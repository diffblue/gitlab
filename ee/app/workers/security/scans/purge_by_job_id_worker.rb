# frozen_string_literal: true

module Security
  module Scans
    class PurgeByJobIdWorker
      include ApplicationWorker
      include Gitlab::EventStore::Subscriber

      feature_category :vulnerability_management
      urgency :low
      worker_resource_boundary :cpu
      data_consistency :always

      idempotent!

      def handle_event(event)
        ::Security::PurgeScansService.purge_by_build_ids(event.data[:job_ids])
      end
    end
  end
end
