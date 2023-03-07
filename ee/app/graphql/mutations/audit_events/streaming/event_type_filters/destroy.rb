# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module EventTypeFilters
        class Destroy < BaseMutation
          graphql_name 'AuditEventsStreamingDestinationEventsRemove'

          authorize :admin_external_audit_events

          argument :destination_id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                   required: true,
                   description: 'Destination URL.'

          argument :event_type_filters, [GraphQL::Types::String],
                   required: true,
                   description: 'List of event type filters to remove from streaming.',
                   prepare: ->(filters, _ctx) do
                     filters.presence || (raise ::Gitlab::Graphql::Errors::ArgumentError,
                                                'event type filters must be present')
                   end

          def resolve(destination_id:, event_type_filters:)
            destination = authorized_find!(destination_id)

            response = ::AuditEvents::Streaming::EventTypeFilters::DestroyService.new(
              destination: destination,
              event_type_filters: event_type_filters,
              current_user: current_user
            ).execute

            if response.success?
              { errors: [] }
            else
              { errors: response.errors }
            end
          end

          private

          def find_object(destination_id)
            GitlabSchema.object_from_id(destination_id, expected_type: ::AuditEvents::ExternalAuditEventDestination)
          end
        end
      end
    end
  end
end
