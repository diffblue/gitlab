# frozen_string_literal: true

module EE
  module ProtectedBranches
    module BaseService
      def sync_scan_finding_approval_rules
        return unless project_or_group.licensed_feature_available?(:security_orchestration_policies)

        project_or_group.all_security_orchestration_policy_configurations.each do |configuration|
          if project_or_group.is_a?(Group)
            Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService
              .new(configuration)
              .execute
          else
            Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService
              .new(configuration)
              .execute(project_or_group.id)
          end
        end
      end
    end
  end
end
