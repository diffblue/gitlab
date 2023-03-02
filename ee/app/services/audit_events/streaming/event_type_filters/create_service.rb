# frozen_string_literal: true

module AuditEvents
  module Streaming
    module EventTypeFilters
      class CreateService < BaseService
        def execute
          begin
            create_event_type_filters!
            log_audit_event
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

        def log_audit_event
          audit_context = {
            name: 'event_type_filters_created',
            author: current_user,
            scope: destination.group,
            target: destination,
            message: "Created audit event type filter(s): #{event_type_filters.to_sentence}"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
