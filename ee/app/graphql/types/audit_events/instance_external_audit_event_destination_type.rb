# frozen_string_literal: true

module Types
  module AuditEvents
    class InstanceExternalAuditEventDestinationType < ::Types::BaseObject
      graphql_name 'InstanceExternalAuditEventDestination'
      description 'Represents an external resource to send instance audit events to'

      authorize :admin_instance_external_audit_events

      implements(ExternalAuditEventDestinationInterface)
    end
  end
end
