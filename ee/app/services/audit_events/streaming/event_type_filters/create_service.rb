# frozen_string_literal: true

module AuditEvents
  module Streaming
    module EventTypeFilters
      class CreateService < BaseService
        def execute
          begin
            create_event_type_filters!
            log_audit_event(name: 'event_type_filters_created', message: 'Created audit event type filter(s)')
          rescue ActiveRecord::RecordInvalid => e
            return ServiceResponse.error(message: e.message)
          end

          ServiceResponse.success
        end

        private

        def create_event_type_filters!
          model.transaction do
            event_type_filters.each do |filter|
              destination.event_type_filters.create!(audit_event_type: filter)
            end
          end
        end
      end
    end
  end
end
