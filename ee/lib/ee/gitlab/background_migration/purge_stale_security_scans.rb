# frozen_string_literal: true

module EE
  module Gitlab
    module BackgroundMigration
      # rubocop:disable Style/Documentation
      module PurgeStaleSecurityScans
        extend ::Gitlab::Utils::Override
        extend ActiveSupport::Concern

        override :perform
        def perform(start_id, end_id)
          updated_scans_count = 0
          relation = ::Gitlab::BackgroundMigration::PurgeStaleSecurityScans::SecurityScan.by_range(start_id..end_id)

          relation.each_batch(of: 500) do |batch|
            updated_scans_count += batch.succeeded.update_all(status: :purged)
          end

          log_info(updated_scans_count)
          mark_job_as_succeeded(start_id, end_id)
        end

        def log_info(updated_scans_count)
          ::Gitlab::BackgroundMigration::Logger.info(
            migrator: self.class.name,
            message: 'Records have been updated',
            updated_scans_count: updated_scans_count
          )
        end

        def mark_job_as_succeeded(*arguments)
          ::Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
            self.class.name.demodulize,
            arguments
          )
        end
      end
    end
  end
end
