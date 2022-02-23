# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ValidatePolicyService < ::BaseProjectService
      def execute
        return error(s_('SecurityOrchestration|Empty policy name')) if blank_name?

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

        !Security::OrchestrationPolicyConfiguration::AVAILABLE_POLICY_TYPES.include?(policy_type)
      end

      def blank_name?
        policy[:name].blank?
      end

      def blank_branch_for_rule?
        return false if policy_type == :scan_result_policy

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

      def policy_type
        policy[:type].to_sym
      end
    end
  end
end
