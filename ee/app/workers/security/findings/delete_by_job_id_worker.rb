# frozen_string_literal: true

module Security
  module Findings
    class DeleteByJobIdWorker
      include ApplicationWorker
      include Gitlab::EventStore::Subscriber

      feature_category :vulnerability_management
      urgency :low
      worker_resource_boundary :cpu
      data_consistency :always

      idempotent!

      def handle_event(event)
        ::Security::Finding.by_build_ids(event.data[:job_ids]).delete_all
      end
    end
  end
end
