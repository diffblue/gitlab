# frozen_string_literal: true

# A common state computation interface to wrap around any_approver rule
class ApprovalWrappedAnyApproverRule < ApprovalWrappedRule
  def name
    'All Members'
  end

  def approved_approvers
    filter_approvers(merge_request.approved_by_users)
  end

  def approved?
    strong_memoize(:approved) do
      approvals_left <= 0
    end
  end

  def commented_approvers
    strong_memoize(:commented_approvers) do
      merge_request.user_note_authors.select do |user|
        merge_request.eligible_for_approval_by?(user)
      end
    end
  end
end
