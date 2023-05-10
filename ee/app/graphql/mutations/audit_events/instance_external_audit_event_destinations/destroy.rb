# frozen_string_literal: true

module Mutations
  module AuditEvents
    module InstanceExternalAuditEventDestinations
      class Destroy < Base
        graphql_name 'InstanceExternalAuditEventDestinationDestroy'

        authorize :admin_instance_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::InstanceExternalAuditEventDestination],
          required: true,
          description: 'ID of the external instance audit event destination to destroy.'

        def resolve(id:)
          destination = find_object(id)

          destination.destroy

          {
            instance_external_audit_event_destination: nil,
            errors: []
          }
        end
      end
    end
  end
end
