# frozen_string_literal: true

module Mutations
  module AuditEvents
    module InstanceExternalAuditEventDestinations
      class Base < BaseMutation
        ERROR_MESSAGE = 'You do not have access to this mutation.'

        def ready?(**args)
          unless current_user&.can?(:admin_instance_external_audit_events)
            raise Gitlab::Graphql::Errors::ResourceNotAvailable, ERROR_MESSAGE
          end

          super
        end

        private

        def find_object(destination_gid)
          destination = GitlabSchema.object_from_id(
            destination_gid,
            expected_type: ::AuditEvents::InstanceExternalAuditEventDestination).sync

          raise_resource_not_available_error! if destination.blank?

          destination
        end

        def audit(destination, action:, extra_context: {})
          audit_context = {
            name: "#{action}_instance_event_streaming_destination",
            author: current_user,
            scope: Gitlab::Audit::InstanceScope.new,
            target: destination,
            message: "#{action.capitalize} instance event streaming destination #{destination.destination_url}"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context.merge(extra_context))
        end
      end
    end
  end
end
