# frozen_string_literal: true

module AuditEvents
  module Streaming
    module EventTypeFilters
      class BaseService
        attr_reader :destination, :event_type_filters, :current_user

        def initialize(destination:, event_type_filters:, current_user:)
          @destination = destination
          @event_type_filters = event_type_filters
          @current_user = current_user
        end
      end
    end
  end
end
