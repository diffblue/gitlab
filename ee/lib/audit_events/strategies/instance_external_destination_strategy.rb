# frozen_string_literal: true

module AuditEvents
  module Strategies
    class InstanceExternalDestinationStrategy < ExternalDestinationStrategy
      def streamable?
        ::License.feature_available?(:external_audit_events) &&
          ::AuditEvents::InstanceExternalAuditEventDestination.exists?
      end

      private

      def destinations
        AuditEvents::InstanceExternalAuditEventDestination.all
      end
    end
  end
end
