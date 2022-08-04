# frozen_string_literal: true

module API
  module Entities
    class MergeRequestApprovalSetting < Grape::Entity
      expose :allow_author_approval
      expose :allow_committer_approval
      expose :allow_overrides_to_approver_list_per_merge_request
      expose :retain_approvals_on_push
      expose :selective_code_owner_removals
      expose :require_password_to_approve
    end
  end
end
