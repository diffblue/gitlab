# frozen_string_literal: true

module Mutations
  module AuditEvents
    module ExternalAuditEventDestinations
      class Update < Base
        graphql_name 'ExternalAuditEventDestinationUpdate'

        include ::Audit::Changes

        UPDATE_EVENT_NAME = 'update_event_streaming_destination'

        authorize :admin_external_audit_events

        argument :id, ::Types::GlobalIDType[::AuditEvents::ExternalAuditEventDestination],
                 required: true,
                 description: 'ID of external audit event destination to update.'

        argument :destination_url, GraphQL::Types::String,
                 required: false,
                 description: 'Destination URL to change.'

        argument :name, GraphQL::Types::String,
                 required: false,
                 description: 'Destination name.'

        field :external_audit_event_destination, ::Types::AuditEvents::ExternalAuditEventDestinationType,
              null: true,
              description: 'Updated destination.'

        def resolve(id:, destination_url: nil, name: nil)
          destination = authorized_find!(id)

          destination_attributes = { destination_url: destination_url,
                                     name: name }.compact

          audit_update(destination) if destination.update(destination_attributes)

          {
            external_audit_event_destination: (destination if destination.persisted?),
            errors: Array(destination.errors)
          }
        end

        private

        def audit_update(destination)
          [:destination_url, :name].each do |column|
            audit_changes(
              column,
              as: column.to_s,
              entity: destination.group,
              model: destination,
              event_type: UPDATE_EVENT_NAME
            )
          end
        end

        def find_object(destination_gid)
          GitlabSchema.object_from_id(destination_gid, expected_type: ::AuditEvents::ExternalAuditEventDestination).sync
        end
      end
    end
  end
end
