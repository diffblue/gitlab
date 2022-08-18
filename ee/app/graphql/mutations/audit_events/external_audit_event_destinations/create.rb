# frozen_string_literal: true

module Mutations
  module AuditEvents
    module ExternalAuditEventDestinations
      class Create < Base
        graphql_name 'ExternalAuditEventDestinationCreate'

        authorize :admin_external_audit_events

        argument :destination_url, GraphQL::Types::String,
                 required: true,
                 description: 'Destination URL.'

        argument :group_path, GraphQL::Types::ID,
                 required: true,
                 description: 'Group path.'

        argument :verification_token, GraphQL::Types::String,
                 required: false,
                 description: 'Verification token.'

        field :external_audit_event_destination, ::Types::AuditEvents::ExternalAuditEventDestinationType,
              null: true,
              description: 'Destination created.'

        def resolve(destination_url:, group_path:, verification_token: nil)
          group = authorized_find!(group_path)
          destination = ::AuditEvents::ExternalAuditEventDestination.new(group: group,
                                                                         destination_url: destination_url,
                                                                         verification_token: verification_token)

          audit(destination, action: :create) if destination.save

          { external_audit_event_destination: (destination if destination.persisted?), errors: Array(destination.errors) }
        end

        private

        def find_object(group_path)
          ::Group.find_by_full_path(group_path)
        end
      end
    end
  end
end
