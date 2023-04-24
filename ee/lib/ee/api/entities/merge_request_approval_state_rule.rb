# frozen_string_literal: true

module EE
  module API
    module Entities
      class MergeRequestApprovalStateRule < MergeRequestApprovalRule
        expose :code_owner, documentation: { type: 'boolean' }
        expose :approved_approvers, as: :approved_by,
          using: ::API::Entities::UserBasic, documentation: { is_array: true }
        expose :approved?, as: :approved, documentation: { type: 'boolean' }
      end
    end
  end
end
