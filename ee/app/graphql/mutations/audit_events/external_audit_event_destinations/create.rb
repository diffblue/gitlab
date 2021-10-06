# frozen_string_literal: true

module Mutations
  module AuditEvents
    module ExternalAuditEventDestinations
      class Create < BaseMutation
        graphql_name 'ExternalAuditEventDestinationCreate'

        authorize :admin_external_audit_events

        argument :destination_url, GraphQL::Types::String,
                 required: true,
                 description: 'Destination URL.'

        argument :group_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Group path.'

        field :external_audit_event_destination, EE::Types::AuditEvents::ExternalAuditEventDestinationType,
              null: true,
              description: 'Destination created.'

        def resolve(destination_url:, group_path:)
          group = authorized_find!(group_path)
          destination = ::AuditEvents::ExternalAuditEventDestination.create(group: group, destination_url: destination_url)

          {
            external_audit_event_destination: destination&.persisted? ? destination : nil,
            errors: Array(destination.errors)
          }
        end

        private

        def find_object(group_path)
          ::GroupFinder.new(current_user).execute(path: group_path)
        end
      end
    end
  end
end
