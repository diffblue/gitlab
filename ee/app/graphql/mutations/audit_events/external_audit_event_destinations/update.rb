# frozen_string_literal: true

module Mutations
  module AuditEvents
    module ExternalAuditEventDestinations
      class Update < Base
        graphql_name 'ExternalAuditEventDestinationUpdate'

        authorize :admin_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                 required: true,
                 description: 'ID of external audit event destination to update.'

        argument :destination_url, GraphQL::Types::String,
                 required: false,
                 description: 'Destination URL to change.'

        field :external_audit_event_destination, ::Types::AuditEvents::ExternalAuditEventDestinationType,
              null: true,
              description: 'Updated destination.'

        def resolve(id:, destination_url:)
          destination = authorized_find!(id)

          audit_update(destination) if destination.update(destination_url: destination_url)

          {
            external_audit_event_destination: (destination if destination.persisted?),
            errors: Array(destination.errors)
          }
        end

        private

        def audit_update(destination)
          return unless destination.previous_changes.any?

          message = "Updated event streaming destination from #{destination.previous_changes['destination_url'].join(' to ')}"

          audit(destination, action: :update, extra_context: { message: message })
        end

        def find_object(destination_gid)
          GitlabSchema.object_from_id(destination_gid, expected_type: ::AuditEvents::ExternalAuditEventDestination).sync
        end
      end
    end
  end
end
