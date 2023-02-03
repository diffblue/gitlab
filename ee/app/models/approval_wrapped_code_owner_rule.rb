# frozen_string_literal: true

# A common state computation interface to wrap around code owner rule
class ApprovalWrappedCodeOwnerRule < ApprovalWrappedRule
  MIN_CODE_OWNER_APPROVALS = 1

  def approvals_required
    strong_memoize(:code_owner_approvals_required) do
      next 0 unless branch_requires_code_owner_approval? && approvers.any?
      next MIN_CODE_OWNER_APPROVALS if approval_rule.approvals_required < MIN_CODE_OWNER_APPROVALS

      approval_rule.approvals_required
    end
  end

  def branch_requires_code_owner_approval?
    return false unless project.code_owner_approval_required_available?
    return false if section_optional?

    ProtectedBranch.branch_requires_code_owner_approval?(project, merge_request.target_branch)
  end

  private

  def section_optional?
    Gitlab::CodeOwners.optional_section?(project, merge_request.target_branch, section)
  end
end
