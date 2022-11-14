# frozen_string_literal: true

module AuditEvents
  module Streaming
    module EventTypeFilters
      class CreateService
        attr_reader :destination, :event_type_filters

        def initialize(destination:, event_type_filters:)
          @destination = destination
          @event_type_filters = event_type_filters
        end

        def execute
          begin
            create_event_type_filters!
          rescue ActiveRecord::RecordInvalid => e
            return ServiceResponse.error(message: e.message)
          end

          ServiceResponse.success
        end

        private

        def create_event_type_filters!
          ::AuditEvents::Streaming::EventTypeFilter.transaction do
            event_type_filters.each do |filter|
              destination.event_type_filters.create!(audit_event_type: filter)
            end
          end
        end
      end
    end
  end
end
