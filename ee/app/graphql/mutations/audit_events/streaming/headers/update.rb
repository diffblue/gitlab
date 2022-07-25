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

            response = ::AuditEvents::Streaming::Headers::UpdateService.new(
              destination: header.external_audit_event_destination,
              params: { header: header, key: key, value: value },
              current_user: current_user
            ).execute

            if response.success?
              { header: response.payload[:header], errors: [] }
            else
              { header: header.reset, errors: response.errors }
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
