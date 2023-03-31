# frozen_string_literal: true

module EE
  module Projects
    module TransferService
      extend ::Gitlab::Utils::Override

      private

      override :execute_system_hooks
      def execute_system_hooks
        super

        Audit::ProjectChangesAuditor.new(current_user, project).execute

        ::Geo::RepositoryRenamedEventStore.new(
          project,
          old_path: project.path,
          old_path_with_namespace: old_path
        ).create!
      end

      override :transfer_missing_group_resources
      def transfer_missing_group_resources(group)
        super

        ::Epics::TransferService.new(current_user, group, project).execute
      end

      override :post_update_hooks
      def post_update_hooks(project)
        super

        ::Elastic::ProjectTransferWorker.perform_async(project.id, old_namespace.id, new_namespace.id)

        delete_scan_result_policies
        unassign_policy_project
        delete_compliance_framework_setting
      end

      override :remove_paid_features
      def remove_paid_features
        revoke_project_access_tokens
        delete_pipeline_subscriptions
        delete_test_cases
      end

      def unassign_policy_project
        return unless project.security_orchestration_policy_configuration

        ::Security::Orchestration::UnassignService.new(container: project, current_user: current_user).execute
      end

      def delete_scan_result_policies
        project.all_security_orchestration_policy_configurations.each do |configuration|
          configuration.delete_scan_finding_rules_for_project(project.id)
        end
      end

      def revoke_project_access_tokens
        return if new_namespace.feature_available_non_trial?(:resource_access_token)

        PersonalAccessTokensFinder
          .new(user: project.bots, impersonation: false)
          .execute
          .update_all(revoked: true)
      end

      # This method is within a transaction
      def delete_pipeline_subscriptions
        return if new_namespace.licensed_feature_available?(:ci_project_subscriptions)

        project_id = project.id
        project.run_after_commit do
          ::Ci::UpstreamProjectsSubscriptionsCleanupWorker.perform_async(project_id)
        end
      end

      def delete_test_cases
        return if new_namespace.licensed_feature_available?(:quality_management)

        project.issues.with_issue_type(:test_case).delete_all
      end

      def delete_compliance_framework_setting
        project.compliance_framework_setting&.delete
      end
    end
  end
end
