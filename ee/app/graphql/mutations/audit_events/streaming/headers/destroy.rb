# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module Headers
        class Destroy < BaseMutation
          graphql_name 'AuditEventsStreamingHeadersDestroy'
          authorize :admin_external_audit_events

          argument :header_id, ::Types::GlobalIDType[::AuditEvents::Streaming::Header],
                   required: true,
                description: 'Header to delete.'

          def resolve(header_id:)
            header = authorized_find!(id: header_id)

            unless Feature.enabled?(:streaming_audit_event_headers, header.external_audit_event_destination.group)
              raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'feature disabled'
            end

            if header.destroy
              { header: nil, errors: [] }
            else
              { header: header, errors: Array(header.errors) }
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
