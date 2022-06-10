# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module BackfillProjectStatisticsContainerRepositorySize
        extend ::Gitlab::Utils::Override
        MIGRATION_PHASE_1_ENDED_AT = Date.new(2022, 01, 23).freeze

        module LogUtils
          MIGRATOR = 'BackfillProjectStatisticsContainerRepositorySize'

          def log_info(message, **extra)
            ::Gitlab::BackgroundMigration::Logger.info(migrator: MIGRATOR, message: message, **extra)
          end
        end

        class Project < ::ApplicationRecord
          include ::Gitlab::Utils::StrongMemoize

          self.table_name = 'projects'

          has_many :container_repositories
          has_one :statistics, class_name: 'ProjectStatistics'

          def container_repositories_size
            strong_memoize(:container_repositories_size) do
              next unless ::Gitlab.com?
              next 0 if container_repositories.empty?
              next unless container_repositories.all_migrated?
              next unless ::ContainerRegistry::GitlabApiClient.supports_gitlab_api?

              ::ContainerRegistry::GitlabApiClient.deduplicated_size(full_path)
            end
          end
        end

        class ContainerRepository < ::ApplicationRecord
          include EachBatch

          self.table_name = 'container_repositories'

          belongs_to :project

          def self.all_migrated?
            # check that the set of non migrated repositories is empty
            where(created_at: ...MIGRATION_PHASE_1_ENDED_AT)
              .where.not(migration_state: 'import_done')
              .empty?
          end
        end

        class ProjectStatistics < ::ApplicationRecord
          include LogUtils
          include ::AfterCommitQueue

          self.table_name = 'project_statistics'

          belongs_to :project

          def refresh_container_registry_size!
            return if ::Gitlab::Database.read_only?

            update_container_registry_size
            schedule_namespace_aggregation_worker

            save!
          end

          def update_container_registry_size
            self.container_registry_size = project.container_repositories_size || 0
            log_info(
              'Got ContainerRegistrySize for project_id',
              project_id: project.id,
              container_registry_size: self.container_registry_size
            )
          end

          def schedule_namespace_aggregation_worker
            run_after_commit do
              ::Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
              log_info('Scheduled Namespaces::ScheduleAggregationWorker', namespace_id: project.namespace_id)
            end
          end
        end

        include LogUtils

        override :perform
        def perform
          each_sub_batch(
            operation_name: :update_container_registry_size,
            batching_scope: -> (relation) {
              relation.where(created_at: MIGRATION_PHASE_1_ENDED_AT..).or(
                relation.where(migration_state: 'import_done')
              ).select(:project_id).distinct
            }
          ) do |sub_batch|
            log_info('Starting SubBatch')
            stats = ProjectStatistics.where(project_id: sub_batch).where(container_registry_size: 0)
            stats.each do |stat|
              # Should trigger an API hit to get the actual container_registry_size for the project, via
              # "project.container_repositories_size"
              # Should schedule a worker to do the same for RootNamespaceStatistic
              stat.refresh_container_registry_size!
            end
            log_info('Ending SubBatch')
          end
        end
      end
    end
  end
end
