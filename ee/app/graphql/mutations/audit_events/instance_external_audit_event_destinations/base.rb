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
          GitlabSchema.object_from_id(
            destination_gid,
            expected_type: ::AuditEvents::InstanceExternalAuditEventDestination).sync
        end
      end
    end
  end
end
