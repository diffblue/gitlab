# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Streaming
      module InstanceHeaders
        class Base < BaseMutation
          ERROR_MESSAGE = 'You do not have access to this mutation.'
          DESTINATION_ERROR_MESSAGE = 'Please provide valid destination id.'

          authorize :admin_instance_external_audit_events

          def ready?(**args)
            unless current_user&.can?(:admin_instance_external_audit_events)
              raise_resource_not_available_error! ERROR_MESSAGE
            end

            super
          end

          private

          def find_destination(destination_id)
            destination = GitlabSchema.object_from_id(
              destination_id, expected_type: ::AuditEvents::InstanceExternalAuditEventDestination
            ).sync

            raise_resource_not_available_error! DESTINATION_ERROR_MESSAGE if destination.blank?

            destination
          end

          def find_header(header_id)
            header = GitlabSchema.object_from_id(
              header_id, expected_type: ::AuditEvents::Streaming::InstanceHeader
            ).sync

            raise_resource_not_available_error! if header.blank?

            header
          end
        end
      end
    end
  end
end
