# frozen_string_literal: true

module Namespaces
  class ProcessSyncEventsWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :sharding
    urgency :high

    deduplicate :until_executed
    idempotent!

    def perform
      ::Ci::ProcessSyncEventsService.new(::Namespaces::SyncEvent, ::Ci::NamespaceMirror).execute
    end
  end
end
