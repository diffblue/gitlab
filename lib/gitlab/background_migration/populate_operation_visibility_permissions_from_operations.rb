# frozen_string_literal: true

module Gitlab
  module BackgroundMigration
    # Migrates the value operations_access_level to the new colums
    # monitor_access_level, deployments_access_level, infrastructure_access_level.
    # The operations_access_level setting is being split into three seperate toggles.
    class PopulateOperationVisibilityPermissionsFromOperations < BatchedMigrationJob
      def perform
        define_batchable_model(batch_table, connection: connection)
          .where(batch_column => start_id..end_id).each_batch(of: sub_batch_size) do |batch|
            batch.update_all('monitor_access_level=operations_access_level,' \
              'infrastructure_access_level=operations_access_level,' \
              ' feature_flags_access_level=operations_access_level,'\
              ' environments_access_level=operations_access_level')
          end

        mark_job_as_succeeded(start_id, end_id)
      end

      private

      def mark_job_as_succeeded(*arguments)
        Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
          'PopulateOperationVisibilityPermissionsFromOperations',
          arguments
        )
      end
    end
  end
end
