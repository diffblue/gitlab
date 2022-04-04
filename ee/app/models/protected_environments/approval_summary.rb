# frozen_string_literal: true

module ProtectedEnvironments
  class ApprovalSummary
    include ActiveModel::Model
    include ::Gitlab::Utils::StrongMemoize

    attr_accessor :deployment

    delegate :environment, :approvals, to: :deployment
    delegate :associated_approval_rules, to: :environment

    def all_rules_approved?
      rules.all? do |rule|
        rule.required_approvals <= rule.deployment_approvals.count(&:approved?)
      end
    end

    def rules
      strong_memoize(:rules) do
        approvals_by_rule_id = approvals.group_by(&:approval_rule_id)

        associated_approval_rules.each do |rule|
          rule.association(:deployment_approvals).target =
            approvals_by_rule_id[rule.id] || Deployments::Approval.none

          rule.association(:deployment_approvals).loaded!
        end
      end
    end
  end
end
