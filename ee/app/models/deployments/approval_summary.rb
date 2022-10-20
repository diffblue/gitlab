# frozen_string_literal: true

module Deployments
  class ApprovalSummary
    include ActiveModel::Model
    include ::Gitlab::Utils::StrongMemoize

    STATUS_PENDING_APPROVAL = 'pending_approval'
    STATUS_REJECTED = 'rejected'
    STATUS_APPROVED = 'approved'
    ALL_STATUSES = [STATUS_APPROVED, STATUS_REJECTED, STATUS_PENDING_APPROVAL].freeze

    attr_accessor :deployment

    delegate :environment, :approvals, to: :deployment
    delegate :associated_approval_rules, to: :environment

    def total_required_approvals
      rules.sum(&:required_approvals)
    end

    def total_pending_approval_count
      rules.sum(&:pending_approval_count)
    end

    def status
      return STATUS_REJECTED if rules.any?(&:rejected?)
      return STATUS_APPROVED if rules.all?(&:approved?)

      STATUS_PENDING_APPROVAL
    end

    def rules
      strong_memoize(:rules) do
        approvals_by_rule_id = approvals.group_by(&:approval_rule_id)

        associated_approval_rules.each do |rule|
          rule.approvals_for_summary = approvals_by_rule_id[rule.id]
        end
      end
    end
  end
end
