# frozen_string_literal: true

module EE
  module ProtectedBranches
    module BlockedByPolicy
      def execute(protected_branch)
        raise ::Gitlab::Access::AccessDeniedError if blocked_by_scan_result_policy?(protected_branch)

        super
      end

      private

      def blocked_by_scan_result_policy?(protected_branch)
        project = protected_branch.project

        return false unless project&.licensed_feature_available?(:security_orchestration_policies)
        return false unless ::Feature.enabled?(:scan_result_policies_block_unprotecting_branches, project)

        service = ::Security::SecurityOrchestrationPolicies::ProtectedBranchesDeletionCheckService.new(project: project)
        protected_from_deletion = service.execute([protected_branch])

        protected_branch.in?(protected_from_deletion)
      end
    end
  end
end
