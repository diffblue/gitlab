# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module Headers
        class Update < BaseMutation
          graphql_name 'AuditEventsStreamingHeadersUpdate'
          authorize :admin_external_audit_events

          argument :header_id, ::Types::GlobalIDType[::AuditEvents::Streaming::Header],
                   required: true,
                description: 'Header to update.'

          argument :key, GraphQL::Types::String,
                   required: true,
                   description: 'Header key.'

          argument :value, GraphQL::Types::String,
                   required: true,
                   description: 'Header value.'

          field :header, ::Types::AuditEvents::Streaming::HeaderType,
                null: true,
                description: 'Updates header.'

          def resolve(header_id:, key:, value:)
            header = authorized_find!(id: header_id)

            unless Feature.enabled?(:streaming_audit_event_headers, header.external_audit_event_destination.group)
              raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'feature disabled'
            end

            if header.update(key: key, value: value)
              { header: header, errors: [] }
            else
              { header: header.reset, errors: Array(header.errors) }
            end
          end

          private

          def find_object(id:)
            GitlabSchema.object_from_id(id, expected_type: ::AuditEvents::Streaming::Header)
          end
        end
      end
    end
  end
end
