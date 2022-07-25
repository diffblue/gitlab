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
            response = ::AuditEvents::Streaming::Headers::CreateService.new(
              destination: authorized_find!(destination_id),
              params: { key: key, value: value },
              current_user: current_user
            ).execute

            if response.success?
              { header: response.payload[:header], errors: [] }
            else
              { header: nil, errors: response.errors }
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
