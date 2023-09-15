# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProtectedBranchesDeletionCheckService < BaseProjectService
      def execute(protected_branches)
        protected_branches.reject do |protected_branch|
          applicable_branches.none? do |branch|
            ::ProtectedBranch.matching(branch, protected_refs: [protected_branch]).any?
          end
        end
      end

      private

      def applicable_branches
        @applicable_branches ||= PolicyBranchesService.new(project: project).scan_result_branches(rules)
      end

      def rules
        project.all_security_orchestration_policy_configurations.flat_map do |config|
          blocking_policies = config.active_scan_result_policies.select do |rule|
            rule.dig(:approval_settings, :block_unprotecting_branches)
          end

          blocking_policies.pluck(:rules).flatten # rubocop: disable CodeReuse/ActiveRecord
        end
      end
    end
  end
end
