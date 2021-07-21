# frozen_string_literal: true

module Geo
  class EventWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    include GeoQueue
    include ::Gitlab::Geo::LogHelpers

    sidekiq_options retry: 3, dead: false
    loggable_arguments 0, 1, 2

    def perform(replicable_name, event_name, payload)
      Geo::EventService.new(replicable_name, event_name, payload).execute
    end
  end
end
