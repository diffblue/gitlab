# frozen_string_literal: true
module Approvals
  class ScanFindingWrappedRuleSet < WrappedRuleSet
    extend ::Gitlab::Utils::Override

    override :wrapped_rules
    def wrapped_rules
      strong_memoize(:wrapped_rules) do
        grouped_merge_request_rules.map do |_, merge_request_rules|
          wrapped_rules_sorted_by_approval(merge_request_rules).first
        end
      end
    end

    private

    def grouped_merge_request_rules
      approval_rules.group_by do |rule|
        [rule.security_orchestration_policy_configuration_id, rule.orchestration_policy_idx]
      end
    end

    def wrapped_rules_sorted_by_approval(merge_request_rules)
      merge_request_rules.map! do |rule|
        ApprovalWrappedRule.wrap(merge_request, rule)
      end
      merge_request_rules.sort_by { |rule| rule.approved? ? 1 : 0 }
    end
  end
end
