# frozen_string_literal: true

module EE
  module API
    module Entities
      class MergeRequestApprovalRule < ApprovalRule
        class SourceRule < Grape::Entity
          expose :approvals_required, documentation: { type: 'integer', example: 2 }
        end

        expose :section, documentation: { example: 'Backend' }
        expose :source_rule, using: MergeRequestApprovalRule::SourceRule
        expose :overridden?, as: :overridden, documentation: { type: 'boolean' }
      end
    end
  end
end
