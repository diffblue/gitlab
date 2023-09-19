# frozen_string_literal: true

module Mutations
  module AuditEvents
    module Instance
      module GoogleCloudLoggingConfigurations
        class Base < BaseMutation
          authorize :admin_instance_external_audit_events

          def ready?(**args)
            raise_resource_not_available_error! unless current_user&.can?(:admin_instance_external_audit_events)

            super
          end

          private

          def find_object(config_gid)
            destination = GitlabSchema.object_from_id(
              config_gid,
              expected_type: ::AuditEvents::Instance::GoogleCloudLoggingConfiguration).sync

            raise_resource_not_available_error! if destination.blank?

            destination
          end

          def audit(config, action:)
            audit_context = {
              name: "instance_google_cloud_logging_configuration_#{action}",
              author: current_user,
              scope: Gitlab::Audit::InstanceScope.new,
              target: config,
              message: "#{action.capitalize} Instance Google Cloud logging configuration with name: #{config.name} " \
                       "project id: #{config.google_project_id_name} and log id: #{config.log_id_name}"
            }

            ::Gitlab::Audit::Auditor.audit(audit_context)
          end
        end
      end
    end
  end
end
