# frozen_string_literal: true

module Types
  module AuditEvents
    class ExternalAuditEventDestinationType < ::Types::BaseObject
      graphql_name 'ExternalAuditEventDestination'
      description 'Represents an external resource to send audit events to'
      authorize :admin_external_audit_events

      implements(ExternalAuditEventDestinationInterface)

      field :group, ::Types::GroupType,
            null: false,
            description: 'Group the destination belongs to.'

      field :headers, ::Types::AuditEvents::Streaming::HeaderType.connection_type,
            null: false,
            description: 'List of additional HTTP headers sent with each event.'

      field :event_type_filters, [GraphQL::Types::String],
            null: false,
            description: 'List of event type filters added for streaming.'
    end
  end
end
