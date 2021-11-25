# frozen_string_literal: true

module Mutations
  module AuditEvents
    module ExternalAuditEventDestinations
      class Base < BaseMutation
        private

        def audit(destination, action:, extra_context: {})
          audit_context = {
            name: "#{action}_event_streaming_destination",
            author: current_user,
            scope: destination.group,
            target: destination.group,
            message: "#{action.capitalize} event streaming destination #{destination.destination_url}"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context.merge(extra_context))
        end
      end
    end
  end
end
