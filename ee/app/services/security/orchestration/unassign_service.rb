# frozen_string_literal: true

module Security
  module Orchestration
    class UnassignService < ::BaseContainerService
      def execute
        return error(_('Policy project doesn\'t exist')) unless security_orchestration_policy_configuration

        old_policy_project = security_orchestration_policy_configuration.security_policy_management_project

        security_orchestration_policy_configuration.delete_scan_finding_rules # To be removed in https://gitlab.com/gitlab-org/gitlab/-/issues/369473#feature-update
        result = security_orchestration_policy_configuration.delete

        if result
          ::Gitlab::Audit::Auditor.audit(
            name: 'policy_project_updated',
            author: current_user,
            scope: container,
            target: old_policy_project,
            message: "Unlinked #{old_policy_project.name} as the security policy project"
          )
          return success
        end

        error(container.security_orchestration_policy_configuration.errors.full_messages.to_sentence)
      end

      private

      delegate :security_orchestration_policy_configuration, to: :container

      def success
        ServiceResponse.success
      end

      def error(message)
        ServiceResponse.error(message: message)
      end
    end
  end
end
