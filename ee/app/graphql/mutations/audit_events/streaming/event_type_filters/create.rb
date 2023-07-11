# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module EventTypeFilters
        class Create < BaseEventTypeFilters::BaseCreate
          graphql_name 'AuditEventsStreamingDestinationEventsAdd'
          authorize :admin_external_audit_events

          argument :destination_id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                   required: true,
                   description: 'Destination id.'

          private

          def find_object(destination_id)
            ::GitlabSchema.object_from_id(destination_id, expected_type: ::AuditEvents::ExternalAuditEventDestination)
          end
        end
      end
    end
  end
end
