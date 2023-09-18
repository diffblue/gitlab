# frozen_string_literal: true

module AuditEvents
  module Strategies
    module Instance
      class GoogleCloudLoggingDestinationStrategy < BaseGoogleCloudLoggingDestinationStrategy
        def streamable?
          ::License.feature_available?(:external_audit_events) &&
            AuditEvents::Instance::GoogleCloudLoggingConfiguration.exists?
        end

        private

        def destinations
          # Only 5 gcp configs are allowed per instance
          AuditEvents::Instance::GoogleCloudLoggingConfiguration.limit(5)
        end
      end
    end
  end
end
