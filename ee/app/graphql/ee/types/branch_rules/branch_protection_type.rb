# frozen_string_literal: true

module EE
  module Types
    module BranchRules
      module BranchProtectionType
        extend ActiveSupport::Concern

        prepended do
          field :code_owner_approval_required,
                type: GraphQL::Types::Boolean,
                null: false,
                description: 'Enforce code owner approvals before allowing a merge.'
        end
      end
    end
  end
end
