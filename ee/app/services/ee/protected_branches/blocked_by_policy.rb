# frozen_string_literal: true

module EE
  module ProtectedBranches
    module BlockedByPolicy
      def execute(protected_branch)
        raise ::Gitlab::Access::AccessDeniedError if blocked_by_scan_result_policy?(protected_branch.project)

        super
      end

      private

      def blocked_by_scan_result_policy?(project)
        return false unless project&.licensed_feature_available?(:security_orchestration_policies)
        return false unless ::Feature.enabled?(:scan_result_policies_block_unprotecting_branches, project)

        project.scan_result_policy_reads.blocking_protected_branches.exists?
      end
    end
  end
end
