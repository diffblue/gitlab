# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module BaseEventTypeFilters
        class BaseDestroy < BaseMutation
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
        end
      end
    end
  end
end
