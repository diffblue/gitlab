# frozen_string_literal: true

module Mutations
  module AuditEvents
    module GoogleCloudLoggingConfigurations
      class Base < BaseMutation
        private

        def audit(config, action:)
          audit_context = {
            name: "google_cloud_logging_configuration_#{action}",
            author: current_user,
            scope: config.group,
            target: config.group,
            message: "#{action.capitalize} Google Cloud logging configuration with name: #{config.name} project id: " \
                     "#{config.google_project_id_name} and log id: #{config.log_id_name}"
          }

          ::Gitlab::Audit::Auditor.audit(audit_context)
        end
      end
    end
  end
end
