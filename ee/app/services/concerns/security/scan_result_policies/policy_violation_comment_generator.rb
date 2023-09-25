# frozen_string_literal: true

module Security
  module ScanResultPolicies
    module PolicyViolationCommentGenerator
      private

      def generate_policy_bot_comment(merge_request, violated_rules, report_type)
        Security::GeneratePolicyViolationCommentWorker.perform_async(
          merge_request.id,
          { 'report_type' => Security::ScanResultPolicies::PolicyViolationComment::REPORT_TYPES[report_type],
            'violated_policy' => violated_rules.any?,
            'requires_approval' => rules_requiring_approval?(violated_rules) }
        )
      end

      def rules_requiring_approval?(approval_rules)
        approval_rules.any? { |rule| rule.approvals_required > 0 }
      end
    end
  end
end
