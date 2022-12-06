# frozen_string_literal: true

module Security
  module Scans
    class PurgeWorker
      include ApplicationWorker
      include CronjobQueue # rubocop: disable Scalability/CronWorkerContext

      feature_category :vulnerability_management
      data_consistency :always

      idempotent!

      def perform
        ::Security::PurgeScansService.purge_stale_records
      end
    end
  end
end
