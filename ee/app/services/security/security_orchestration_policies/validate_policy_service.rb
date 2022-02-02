# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ValidatePolicyService < ::BaseProjectService
      def execute
        return success if policy_disabled?

        return error(s_('SecurityOrchestration|Invalid policy type')) if invalid_policy_type?
        return error(s_('SecurityOrchestration|Policy cannot be enabled without branch information')) if blank_branch_for_rule?
        return error(s_('SecurityOrchestration|Policy cannot be enabled for non-existing branches (%{branches})') % { branches: missing_branch_names.join(', ') }) if missing_branch_for_rule?

        success
      end

      private

      def policy_disabled?
        !policy&.[](:enabled)
      end

      def invalid_policy_type?
        return true if policy[:type].blank?

        !Security::OrchestrationPolicyConfiguration::AVAILABLE_POLICY_TYPES.include?(policy[:type].to_sym)
      end

      def blank_branch_for_rule?
        policy[:rules].any? { |rule| rule[:clusters].blank? && rule[:branches].blank? }
      end

      def missing_branch_for_rule?
        return false if project.blank?

        missing_branch_names.present?
      end

      def missing_branch_names
        strong_memoize(:missing_branch_names) do
          policy[:rules]
            .select { |rule| rule[:clusters].blank? }
            .flat_map { |rule| rule[:branches] }
            .compact
            .uniq
            .select { |pattern| RefMatcher.new(pattern).matching(branches_for_project).blank? }
        end
      end

      def policy
        @policy ||= params[:policy]
      end

      def branches_for_project
        strong_memoize(:branches_for_project) do
          repository.branch_names
        end
      end
    end
  end
end
