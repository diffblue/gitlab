# frozen_string_literal: true

module AuditEvents
  class ExternalDestinationStreamer
    attr_reader :event_name, :audit_event

    STRATEGIES = [
      AuditEvents::Strategies::GroupExternalDestinationStrategy,
      AuditEvents::Strategies::InstanceExternalDestinationStrategy,
      AuditEvents::Strategies::GoogleCloudLoggingDestinationStrategy
    ].freeze

    def initialize(event_name, audit_event)
      @event_name = event_name
      @audit_event = audit_event
    end

    def stream_to_destinations
      streamable_strategies.each(&:execute)
    end

    def streamable?
      !streamable_strategies.empty?
    end

    private

    def streamable_strategies
      @streamable_strategies = STRATEGIES.filter_map do |strategy|
        strategy_instance = strategy.new(event_name, audit_event)
        strategy_instance if strategy_instance.streamable?
      end.compact
    end
  end
end
