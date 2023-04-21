# frozen_string_literal: true

module EE
  module API
    module Entities
      class ApprovalRule < ApprovalRuleShort
        def initialize(object, options = {})
          presenter = ::ApprovalRulePresenter.new(object, current_user: options[:current_user])
          super(presenter, options)
        end

        expose :approvers, as: :eligible_approvers,
          using: ::API::Entities::UserBasic, documentation: { is_array: true }
        expose :approvals_required, documentation: { type: 'integer', example: 2 }
        expose :users, using: ::API::Entities::UserBasic, documentation: { is_array: true }
        expose :groups, using: ::API::Entities::Group, documentation: { is_array: true }
        expose :contains_hidden_groups?, as: :contains_hidden_groups, documentation: { type: 'boolean' }
      end
    end
  end
end
