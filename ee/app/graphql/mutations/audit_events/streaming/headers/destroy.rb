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

            response = ::AuditEvents::Streaming::Headers::DestroyService.new(
              destination: header.external_audit_event_destination,
              params: { header: header },
              current_user: current_user
            ).execute

            if response.success?
              { header: nil, errors: [] }
            else
              { header: header, errors: response.errors }
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
