# frozen_string_literal: true

module Mutations
  module AuditEvents
    module ExternalAuditEventDestinations
      class Destroy < Base
        graphql_name 'ExternalAuditEventDestinationDestroy'

        authorize :admin_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                 required: true,
                 description: 'ID of external audit event destination to destroy.'

        def resolve(id:)
          destination = authorized_find!(id)

          if destination.destroy
            audit(destination, action: :destroy)
          end

          {
            external_audit_event_destination: nil,
            errors: []
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
