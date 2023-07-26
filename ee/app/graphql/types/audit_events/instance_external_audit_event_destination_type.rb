# frozen_string_literal: true

module Types
  module AuditEvents
    class InstanceExternalAuditEventDestinationType < ::Types::BaseObject
      graphql_name 'InstanceExternalAuditEventDestination'
      description 'Represents an external resource to send instance audit events to'

      authorize :admin_instance_external_audit_events

      implements ExternalAuditEventDestinationInterface

      field :headers, ::Types::AuditEvents::Streaming::InstanceHeaderType.connection_type,
        null: false,
        description: 'List of additional HTTP headers sent with each event.'
    end
  end
end
