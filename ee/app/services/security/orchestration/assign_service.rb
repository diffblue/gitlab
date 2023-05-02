# frozen_string_literal: true

module Security
  module Orchestration
    class AssignService < ::BaseContainerService
      def execute
        validate_access!

        res = create_or_update_security_policy_configuration

        return success if res

      rescue ActiveRecord::RecordNotFound => _
        error(_('Policy project doesn\'t exist'))
      rescue ActiveRecord::RecordInvalid => _
        error(_('Couldn\'t assign policy to project or group'))
      end

      private

      def validate_access!
        return if current_user.can?(:modify_security_policy, container)

        raise Gitlab::Access::AccessDeniedError
      end

      def create_or_update_security_policy_configuration
        return unassign_policy_project if policy_project_id.blank? && has_existing_policy?

        policy_project = Project.find(policy_project_id)

        return reassign_policy_project(policy_project) if has_existing_policy?

        assign_policy_project(policy_project)
      end

      def assign_policy_project(policy_project)
        create_result = container.create_security_orchestration_policy_configuration! do |p|
          p.security_policy_management_project_id = policy_project.id
        end

        create_security_policy_project_bot(create_result)

        if create_result
          audit(policy_project, "Linked #{policy_project.name} as the security policy project")
          Security::SyncScanPoliciesWorker.perform_async(container.security_orchestration_policy_configuration.id)
        end

        create_result
      end

      def unassign_policy_project
        result = UnassignService.new(container: container, current_user: current_user).execute

        result.success?
      end

      def reassign_policy_project(policy_project)
        configuration = container.security_orchestration_policy_configuration
        old_policy_project = configuration.security_policy_management_project

        update_result = nil
        configuration.transaction do
          configuration.delete_scan_finding_rules
          update_result = configuration.update!(security_policy_management_project_id: policy_project.id)
        end

        if update_result
          audit(
            policy_project,
            "Changed the linked security policy project from #{old_policy_project.name} to #{policy_project.name}"
          )

          Security::SyncScanPoliciesWorker.perform_async(configuration.id)
        end

        update_result
      end

      def audit(policy_project, message)
        ::Gitlab::Audit::Auditor.audit(
          name: 'policy_project_updated',
          author: current_user,
          scope: container,
          target: policy_project,
          message: message
        )
      end

      def success
        ServiceResponse.success(payload: { policy_project: policy_project_id })
      end

      def error(message)
        ServiceResponse.error(payload: { policy_project: policy_project_id }, message: message)
      end

      def has_existing_policy?
        container.security_orchestration_policy_configuration.present?
      end

      def policy_project_id
        params[:policy_project_id]
      end

      def create_security_policy_project_bot(configuration)
        return unless container.is_a?(Project) && Feature.enabled?(:scan_execution_bot_users, container)

        Security::OrchestrationConfigurationCreateBotWorker.perform_async(configuration.id, current_user.id)
      end
    end
  end
end
