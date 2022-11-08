# frozen_string_literal: true

module API
  module Entities
    class MergeRequestApprovalSetting < Grape::Entity
      expose :allow_author_approval, documentation: { type: 'boolean', example: true }
      expose :allow_committer_approval, documentation: { type: 'boolean', example: true }
      expose :allow_overrides_to_approver_list_per_merge_request, documentation: { type: 'boolean', example: true }
      expose :retain_approvals_on_push, documentation: { type: 'boolean', example: true }
      expose :selective_code_owner_removals, documentation: { type: 'boolean', example: true }
      expose :require_password_to_approve, documentation: { type: 'boolean', example: true }
    end
  end
end
