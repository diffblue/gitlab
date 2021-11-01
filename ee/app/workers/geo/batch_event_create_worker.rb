# frozen_string_literal: true

module Geo
  class BatchEventCreateWorker
    include ApplicationWorker

    data_consistency :always

    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    idempotent!

    def perform(events)
      log_info('Executing Geo::BatchEventCreateWorker', events_count: events.size)

      ::Gitlab::Geo::Replicator.bulk_create_events(events)
    end
  end
end
