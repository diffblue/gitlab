# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      module BackfillProjectStatisticsStorageSizeWithoutUploadsSize
        class Project < ::ApplicationRecord
          self.table_name = 'projects'

          has_one :statistics,
          class_name: '::EE::Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutUploadsSize::ProjectStatistics' # rubocop:disable Layout/LineLength
        end

        class ProjectStatistics < ::ApplicationRecord
          include ::EachBatch

          self.table_name = 'project_statistics'

          belongs_to :project,
          class_name: '::EE::Gitlab::BackgroundMigration::BackfillProjectStatisticsStorageSizeWithoutUploadsSize::Project' # rubocop:disable Layout/LineLength

          def get_storage_size
            repository_size +
              wiki_size +
              lfs_objects_size +
              build_artifacts_size +
              packages_size +
              snippets_size +
              pipeline_artifacts_size
          end

          def update_storage_size
            new_storage_size = get_storage_size

            # Only update storage_size if storage_size needs updating
            return unless storage_size != new_storage_size

            self.storage_size = new_storage_size
            save!

            ::Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
            log_with_data('Scheduled Namespaces::ScheduleAggregationWorker')
          end

          def wiki_size
            super.to_i
          end

          def snippets_size
            super.to_i
          end

          private

          def log_with_data(log_line)
            log_info(
              log_line,
              project_id: project.id,
              uploads_size: uploads_size,
              storage_size: storage_size,
              namespace_id: project.namespace_id
            )
          end

          def log_info(message, **extra)
            ::Gitlab::BackgroundMigration::Logger.info(
              migrator: 'BackfillProjectStatisticsStorageSizeWithoutUploadsSize',
              message: message,
              **extra
            )
          end
        end

        extend ActiveSupport::Concern

        prepended do
          scope_to ->(relation) {
            relation.where.not(uploads_size: 0)
          }
          operation_name :update_storage_size
        end

        def perform
          return unless ::Gitlab.dev_or_test_env? || ::Gitlab::CurrentSettings.should_check_namespace_plan?

          each_sub_batch do |sub_batch|
            ProjectStatistics.merge(sub_batch).each(&:update_storage_size)
          end
        end
      end
    end
  end
end
