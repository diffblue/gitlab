# frozen_string_literal: true

module Mutations
  module AuditEvents
    module ExternalAuditEventDestinations
      class Update < BaseMutation
        graphql_name 'ExternalAuditEventDestinationUpdate'

        authorize :admin_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                 required: true,
                 description: 'ID of external audit event destination to destroy.'

        argument :destinationUrl, GraphQL::Types::String,
                 required: false,
                 description: 'Destination URL to change.'

        field :external_audit_event_destination, EE::Types::AuditEvents::ExternalAuditEventDestinationType,
              null: true,
              description: 'Updated destination.'

        def resolve(id:, destination_url:)
          destination = authorized_find!(id)

          destination.update(destination_url: destination_url) if destination

          {
            external_audit_event_destination: destination,
            errors: Array(destination.errors)
          }
        end

        private

        def find_object(destination_gid)
          GitlabSchema.object_from_id(destination_gid, expected_type: ::AuditEvents::ExternalAuditEventDestination).sync
        end
      end
    end
  end
end
