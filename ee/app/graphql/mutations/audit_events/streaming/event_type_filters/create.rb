# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module EventTypeFilters
        class Create < BaseMutation
          graphql_name 'AuditEventsStreamingDestinationEventsAdd'
          authorize :admin_external_audit_events

          argument :destination_id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                   required: true,
                   description: 'Destination id.'

          argument :event_type_filters, [GraphQL::Types::String],
                   required: true,
                   description: 'List of event type filters to add for streaming.',
                   prepare: ->(filters, _ctx) do
                     filters.presence || (raise ::Gitlab::Graphql::Errors::ArgumentError,
                                                'event type filters must be present')
                   end

          field :event_type_filters, [GraphQL::Types::String],
                null: true,
                description: 'Event type filters present.'

          def resolve(destination_id:, event_type_filters:)
            destination = authorized_find!(destination_id)

            response = ::AuditEvents::Streaming::EventTypeFilters::CreateService.new(
              destination: destination,
              event_type_filters: event_type_filters,
              current_user: current_user
            ).execute

            if response.success?
              { event_type_filters: destination.event_type_filters, errors: [] }
            else
              { event_type_filters: destination.event_type_filters, errors: response.errors }
            end
          end

          private

          def find_object(destination_id)
            ::GitlabSchema.object_from_id(destination_id, expected_type: ::AuditEvents::ExternalAuditEventDestination)
          end
        end
      end
    end
  end
end
