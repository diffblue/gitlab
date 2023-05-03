# frozen_string_literal: true

module Mutations
  module AuditEvents
    module InstanceExternalAuditEventDestinations
      class Create < Base
        graphql_name 'InstanceExternalAuditEventDestinationCreate'

        authorize :admin_instance_external_audit_events

        argument :destination_url, GraphQL::Types::String,
          required: true,
          description: 'Destination URL.'

        field :instance_external_audit_event_destination,
          ::Types::AuditEvents::InstanceExternalAuditEventDestinationType,
          null: true,
          description: 'Destination created.'

        def resolve(destination_url:)
          destination = ::AuditEvents::InstanceExternalAuditEventDestination.new(destination_url: destination_url)
          destination.save

          {
            instance_external_audit_event_destination: (destination if destination.persisted?),
            errors: Array(destination.errors)
          }
        end
      end
    end
  end
end
