# frozen_string_literal: true

# Model for join table between ApprovalProjectRule and ProtectedBranch
class ApprovalProjectRulesProtectedBranch < ApplicationRecord
  extend SuppressCompositePrimaryKeyWarning
  belongs_to :protected_branch
  belongs_to :approval_project_rule

  def branch_name
    protected_branch.name
  end
end
