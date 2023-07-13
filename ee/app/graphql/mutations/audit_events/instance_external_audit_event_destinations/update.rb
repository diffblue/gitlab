# frozen_string_literal: true

module Mutations
  module AuditEvents
    module InstanceExternalAuditEventDestinations
      class Update < Base
        graphql_name 'InstanceExternalAuditEventDestinationUpdate'

        authorize :admin_instance_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::InstanceExternalAuditEventDestination],
          required: true,
          description: 'ID of the external instance audit event destination to update.'

        argument :destination_url, GraphQL::Types::String,
          required: false,
          description: 'Destination URL to change.'

        argument :name, GraphQL::Types::String,
          required: false,
          description: 'Destination name.'

        field :instance_external_audit_event_destination,
          ::Types::AuditEvents::InstanceExternalAuditEventDestinationType,
          null: true,
          description: 'Updated destination.'

        def resolve(id:, destination_url: nil, name: nil)
          destination = find_object(id)

          destination_attributes = { destination_url: destination_url, name: name }.compact

          destination.update(destination_attributes)

          {
            instance_external_audit_event_destination: (destination if destination.persisted?),
            errors: Array(destination.errors)
          }
        end
      end
    end
  end
end
