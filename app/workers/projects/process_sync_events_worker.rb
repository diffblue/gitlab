# frozen_string_literal: true

module Projects
  class ProcessSyncEventsWorker
    include ApplicationWorker

    data_consistency :always

    feature_category :sharding
    urgency :high

    deduplicate :until_executed
    idempotent!

    def perform
      ::Ci::ProcessSyncEventsService.new(::Projects::SyncEvent, ::Ci::ProjectMirror).execute
    end
  end
end
