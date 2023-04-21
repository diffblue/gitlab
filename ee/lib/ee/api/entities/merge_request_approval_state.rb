# frozen_string_literal: true

module EE
  module API
    module Entities
      class MergeRequestApprovalState < Grape::Entity
        expose :approval_rules_overwritten, documentation: { type: 'boolean' } do |approval_state|
          approval_state.approval_rules_overwritten?
        end

        expose :wrapped_approval_rules, as: :rules,
          using: MergeRequestApprovalStateRule, documentation: { is_array: true }
      end
    end
  end
end
