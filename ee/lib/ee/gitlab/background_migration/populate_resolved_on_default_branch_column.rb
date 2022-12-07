# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module PopulateResolvedOnDefaultBranchColumn
        def perform(*project_ids)
          project_ids.flatten.each { |project_id| PopulateResolvedOnDefaultBranchColumnForProject.perform(project_id) }
        end

        module Routable
          extend ActiveSupport::Concern

          included do
            has_one :route, as: :source
          end

          def full_path
            route&.path || build_full_path
          end

          def build_full_path
            if parent && path
              parent.full_path + '/' + path
            else
              path
            end
          end
        end

        module Visibility
          PUBLIC_LEVEL = 20

          def public?
            visibility_level == PUBLIC_LEVEL
          end
        end

        # This class depends on Gitlab::CurrentSettings
        class Project < ActiveRecord::Base
          include Routable
          include Visibility
          include ::Gitlab::Utils::StrongMemoize

          self.table_name = 'projects'

          # These are the artifact file types to query
          # only security report related artifacts.
          # sast: 5
          # dependency_scanning: 6
          # container_scanning: 7
          # dast: 8
          # secret_detection: 21
          # coverage_fuzzing: 23
          FILE_TYPES = [5, 6, 7, 8, 21, 23].freeze
          LATEST_PIPELINE_WITH_REPORTS_SQL = <<~SQL
            SELECT
              "ci_pipelines"."id"
            FROM
              "ci_pipelines"
            WHERE
              ("ci_pipelines"."id" IN (
                SELECT
                  "ci_pipelines"."id"
                FROM
                  "ci_pipelines"
                WHERE
                  ci_pipelines.project_id = %{project_id}
                  AND ci_pipelines.ref = %{ref}
                  AND ci_pipelines.status IN ('success')
                ORDER BY
                  "ci_pipelines"."id" DESC
                LIMIT 100))
              AND (EXISTS (
                SELECT
                  1
                FROM
                  "ci_builds"
                WHERE
                  "ci_builds"."type" = 'Ci::Build'
                  AND ("ci_builds"."retried" IS FALSE OR "ci_builds"."retried" IS NULL)
                  AND (EXISTS (
                    SELECT
                      1
                    FROM
                      "ci_job_artifacts"
                    WHERE
                      (ci_builds.id = ci_job_artifacts.job_id)
                      AND "ci_job_artifacts"."file_type" IN (%{file_types})))
                  AND (ci_pipelines.id = ci_builds.commit_id)))
            ORDER BY
              "ci_pipelines"."id" DESC
            LIMIT 1
          SQL

          belongs_to :namespace
          alias_method :parent, :namespace

          has_one :route, as: :source
          has_many :vulnerabilities

          def self.polymorphic_name
            'Project'
          end

          def resolved_vulnerabilities
            return Vulnerability.none unless latest_pipeline_id

            vulnerabilities.not_found_in_pipeline_id(latest_pipeline_id)
          end

          private

          delegate :connection, to: :'self.class', private: true

          def latest_pipeline_id
            strong_memoize(:latest_pipeline_id) { pipeline_with_reports&.fetch('id') }
          end

          def pipeline_with_reports
            connection.execute(pipeline_with_reports_sql).first
          end

          def pipeline_with_reports_sql
            format(LATEST_PIPELINE_WITH_REPORTS_SQL, project_id: id, ref: connection.quote(default_branch), file_types: FILE_TYPES.join(', '))
          end

          def default_branch
            @default_branch ||= repository.root_ref || default_branch_from_preferences
          end

          def repository
            @repository ||= Repository.new(full_path, self, shard: repository_storage, disk_path: storage.disk_path)
          end

          def storage
            @storage ||=
              if hashed_repository_storage?
                Storage::Hashed.new(self)
              else
                Storage::LegacyProject.new(self)
              end
          end

          def hashed_repository_storage?
            storage_version.to_i >= 1
          end

          def default_branch_from_preferences
            ::Gitlab::CurrentSettings.default_branch_name if repository.empty?
          end
        end

        module Storage
          class Hashed
            attr_accessor :container

            REPOSITORY_PATH_PREFIX = '@hashed'

            def initialize(container)
              @container = container
            end

            def base_dir
              "#{REPOSITORY_PATH_PREFIX}/#{disk_hash[0..1]}/#{disk_hash[2..3]}" if disk_hash
            end

            def disk_path
              "#{base_dir}/#{disk_hash}" if disk_hash
            end

            private

            def disk_hash
              @disk_hash ||= Digest::SHA2.hexdigest(container.id.to_s) if container.id
            end
          end

          class LegacyProject
            attr_accessor :project

            def initialize(project)
              @project = project
            end

            def disk_path
              project.full_path
            end
          end
        end

        class Namespace < ActiveRecord::Base
          include Routable
          include Visibility

          self.table_name = 'namespaces'

          belongs_to :parent, class_name: 'Namespace'

          def self.find_sti_class(type_name)
            super("EE::Gitlab::BackgroundMigration::PopulateResolvedOnDefaultBranchColumn::#{type_name}")
          end
        end

        class Group < Namespace
          def self.polymorphic_name
            'Group'
          end
        end

        class Route < ActiveRecord::Base
          self.table_name = 'routes'
        end

        class Vulnerability < ActiveRecord::Base
          include EachBatch

          self.table_name = 'vulnerabilities'

          scope :not_found_in_pipeline_id, -> (pipeline_id) do
            where(<<~SQL)
              NOT EXISTS (
                SELECT 1
                FROM vulnerability_occurrences vo
                INNER JOIN vulnerability_occurrence_pipelines vop ON vop.occurrence_id = vo.id
                WHERE vo.vulnerability_id = vulnerabilities.id AND vop.pipeline_id = #{pipeline_id}
              )
            SQL
          end
        end

        # This class depends on following classes
        #   GlRepository class defined in `lib/gitlab/gl_repository.rb`
        #   Repository class defined in `lib/gitlab/git/repository.rb`.
        class Repository
          def initialize(full_path, container, shard:, disk_path: nil, repo_type: ::Gitlab::GlRepository::PROJECT)
            @full_path = full_path
            @shard = shard
            @disk_path = disk_path || full_path
            @container = container
            @commit_cache = {}
            @repo_type = repo_type
          end

          def root_ref
            raw_repository&.root_ref
          rescue Gitlab::Git::Repository::NoRepository
          end

          def empty?
            return true unless exists?

            !has_visible_content?
          end

          private

          attr_reader :full_path, :shard, :disk_path, :container, :repo_type

          delegate :has_visible_content?, to: :raw_repository, private: true

          def exists?
            return false unless full_path

            raw_repository.exists?
          end

          def raw_repository
            return unless full_path

            @raw_repository ||= initialize_raw_repository
          end

          def initialize_raw_repository
            ::Gitlab::Git::Repository.new(shard,
                                        disk_path + '.git',
                                        repo_type.identifier_for_container(container),
                                        container.full_path)
          end
        end

        class PopulateResolvedOnDefaultBranchColumnForProject
          def self.perform(project_id)
            new(project_id).perform
          end

          def initialize(project_id)
            self.project_id = project_id
            self.updated_count = 0
          end

          def perform
            update_vulnerabilities
            log_info
          rescue StandardError => e
            log_error(e)
          end

          attr_accessor :project_id, :updated_count

          private

          def update_vulnerabilities
            return if project.resolved_vulnerabilities.none?

            project.vulnerabilities.each_batch(of: 100) do |relation|
              self.updated_count += relation.merge(project.resolved_vulnerabilities)
                                            .update_all(resolved_on_default_branch: true)
            end
          end

          def log_info
            ::Gitlab::BackgroundMigration::Logger.info(
              migrator: 'PopulateResolvedOnDefaultBranchColumnForProject',
              message: 'Project migrated',
              updated_count: updated_count,
              project_id: project_id
            )
          end

          def log_error(error)
            ::Gitlab::BackgroundMigration::Logger.error(
              migrator: 'PopulateResolvedOnDefaultBranchColumnForProject',
              message: error.message,
              project_id: project_id
            )
          end

          def project
            @project ||= Project.find(project_id)
          end
        end
      end
    end
  end
end
