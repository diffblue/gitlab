# frozen_string_literal: true

module Ci
  class ProcessSyncEventsService
    include Gitlab::Utils::StrongMemoize

    BATCH_SIZE = 1000

    def initialize(sync_event_class, sync_class)
      @sync_event_class = sync_event_class
      @sync_class = sync_class
    end

    def execute
      return unless ::Feature.enabled?(:ci_namespace_project_mirrors, default_enabled: :yaml)

      process_events
      enqueue_worker_if_there_still_event
    end

    private

    def process_events
      events = @sync_event_class
                 .preload_synced_relation
                 .order_by_id_asc
                 .limit(BATCH_SIZE)
                 .to_a

      return if events.empty?

      min = events[0]
      max = events[-1]

      events.each { |event| @sync_class.sync!(event) }
      @sync_event_class.for_id(min.id..max.id).delete_all
    end

    def enqueue_worker_if_there_still_event
      @sync_event_class.enqueue_worker if @sync_event_class.exists?
    end
  end
end
