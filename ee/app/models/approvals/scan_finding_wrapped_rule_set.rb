# frozen_string_literal: true
module Approvals
  class ScanFindingWrappedRuleSet < WrappedRuleSet
    extend ::Gitlab::Utils::Override

    override :wrapped_rules
    def wrapped_rules
      strong_memoize(:wrapped_rules) do
        if ::Feature.enabled?(:scan_result_policy, merge_request.project, default_enabled: :yaml)
          grouped_merge_request_rules = approval_rules.group_by(&:orchestration_policy_idx)
          grouped_merge_request_rules.map do |_, merge_request_rules|
            wrapped_rules_sorted_by_approval(merge_request_rules).first
          end
        else
          []
        end
      end
    end

    private

    def wrapped_rules_sorted_by_approval(merge_request_rules)
      merge_request_rules.map! do |rule|
        ApprovalWrappedRule.wrap(merge_request, rule)
      end
      merge_request_rules.sort_by {|rule| rule.approved? ? 1 : 0}
    end
  end
end
