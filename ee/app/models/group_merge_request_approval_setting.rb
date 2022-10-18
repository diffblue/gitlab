# frozen_string_literal: true

class GroupMergeRequestApprovalSetting < ApplicationRecord
  self.primary_key = :group_id

  belongs_to :group, inverse_of: :group_merge_request_approval_setting

  validates :group, presence: true
  validates :allow_author_approval,
            :allow_committer_approval,
            :allow_overrides_to_approver_list_per_merge_request,
            :retain_approvals_on_push,
            :require_password_to_approve,
            inclusion: { in: [true, false], message: N_('must be a boolean value') }

  scope :find_or_initialize_by_group, ->(group) { find_or_initialize_by(group: group) }

  AUDIT_LOG_ALLOWLIST = { allow_author_approval: 'prevent merge request approval from authors',
                          allow_committer_approval: 'prevent merge request approval from committers',
                          allow_overrides_to_approver_list_per_merge_request:
                            'prevent users from modifying MR approval rules in merge requests',
                          retain_approvals_on_push: 'require new approvals when new commits are added to an MR',
                          require_password_to_approve: 'require user password for approvals' }.freeze

  def selective_code_owner_removals
    false
  end
end
