# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module Headers
        class Create < BaseMutation
          graphql_name 'AuditEventsStreamingHeadersCreate'
          authorize :admin_external_audit_events

          argument :key, GraphQL::Types::String,
                   required: true,
                   description: 'Header key.'

          argument :value, GraphQL::Types::String,
                   required: true,
                   description: 'Header value.'

          argument :destination_id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                   required: true,
                description: 'Destination to associate header with.'

          field :header, ::Types::AuditEvents::Streaming::HeaderType,
                null: true,
                description: 'Created header.'

          def resolve(destination_id:, key:, value:)
            destination = authorized_find!(destination_id)
            unless Feature.enabled?(:streaming_audit_event_headers, destination.group)
              raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'feature disabled'
            end

            header = destination.headers.new(key: key, value: value)

            { header: (header if header.save), errors: Array(header.errors) }
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
