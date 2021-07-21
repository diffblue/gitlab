# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module PopulateLatestPipelineIds
        extend ::Gitlab::Utils::Override

        module LogUtils
          MIGRATOR = 'PopulateLatestPipelineIds'

          def log_info(log_attributes)
            ::Gitlab::BackgroundMigration::Logger.info(log_attributes.merge(migrator: MIGRATOR))
          end
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

        class Namespace < ActiveRecord::Base
          include Routable

          self.table_name = 'namespaces'
          self.inheritance_column = :_type_disabled

          belongs_to :parent, class_name: '::EE::Gitlab::BackgroundMigration::PopulateLatestPipelineIds::Namespace'

          def self.polymorphic_name
            'Namespace'
          end
        end

        class Route < ActiveRecord::Base
          self.table_name = 'routes'
        end

        class Project < ActiveRecord::Base # rubocop:disable Metrics/ClassLength
          include Routable
          include LogUtils

          self.table_name = 'projects'

          DEFAULT_LETTER_GRADE = 0
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
                  AND ci_pipelines.status IN ('success', 'failed', 'canceled', 'skipped')
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

          belongs_to :namespace, class_name: '::EE::Gitlab::BackgroundMigration::PopulateLatestPipelineIds::Namespace'
          alias_method :parent, :namespace

          has_many :all_pipelines, class_name: '::EE::Gitlab::BackgroundMigration::PopulateLatestPipelineIds::Pipeline'
          has_one :project_setting, class_name: '::Gitlab::BackgroundMigration::PopulateLatestPipelineIds::ProjectSetting'
          has_one :route, as: :source, class_name: '::EE::Gitlab::BackgroundMigration::PopulateLatestPipelineIds::Route'

          def self.polymorphic_name
            'Project'
          end

          def self.by_range(start_id, end_id)
            joins(:project_setting)
              .merge(::Gitlab::BackgroundMigration::PopulateLatestPipelineIds::ProjectSetting.has_vulnerabilities_without_latest_pipeline_set)
              .where(id: (start_id..end_id))
          end

          def stats_tuple
            unless latest_pipeline_id
              log_info(message: 'No latest_pipeline_id found', project_id: id)

              return
            end

            log_info(message: 'latest_pipeline_id found', project_id: id)

            [id, DEFAULT_LETTER_GRADE, latest_pipeline_id, current_time, current_time].join(', ').then { |s| "(#{s})" }
          rescue StandardError => e
            ::Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e)

            nil
          end

          private

          delegate :connection, to: :'self.class', private: true

          def current_time
            @current_time ||= connection.quote(Time.zone.now)
          end

          def latest_pipeline_id
            @latest_pipeline_id ||= pipeline_with_reports&.fetch('id')
          end

          def pipeline_with_reports
            connection.execute(pipeline_with_reports_sql).first
          end

          def pipeline_with_reports_sql
            log_info(message: 'Pipeline with reports SQL requested', project_id: id, ref: default_branch)

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
          rescue ::Gitlab::Git::Repository::NoRepository
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

        class VulnerabilityStatistic < ActiveRecord::Base
          extend LogUtils

          self.table_name = 'vulnerability_statistics'

          UPSERT_SQL = <<~SQL
            INSERT INTO vulnerability_statistics
              (project_id, letter_grade, latest_pipeline_id, created_at, updated_at)
              VALUES
              %{insert_tuples}
            ON CONFLICT (project_id)
            DO UPDATE SET
              latest_pipeline_id = COALESCE(vulnerability_statistics.latest_pipeline_id, EXCLUDED.latest_pipeline_id),
              updated_at = EXCLUDED.updated_at
          SQL

          class << self
            def update_latest_pipeline_ids_for(projects)
              upsert_tuples = projects.map(&:stats_tuple).compact

              return log_info(message: 'No projects to update') unless upsert_tuples.present?

              run_upsert(upsert_tuples)
            end

            private

            def run_upsert(tuples)
              upsert_sql = format(UPSERT_SQL, insert_tuples: tuples.join(', '))

              connection.execute(upsert_sql)
              log_info(message: 'Update query has been executed')
            end
          end
        end

        include LogUtils

        override :perform
        def perform(start_id, end_id)
          log_info(message: 'Migration started', start_id: start_id, end_id: end_id)

          projects = Project.by_range(start_id, end_id)

          log_info(message: 'Projects fetched', count: projects.length)

          VulnerabilityStatistic.update_latest_pipeline_ids_for(projects)
        end
      end
    end
  end
end
