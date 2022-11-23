# frozen_string_literal: true

module EE
  module Types
    module BranchRules
      module BranchProtectionType
        extend ActiveSupport::Concern

        prepended do
          field :unprotect_access_levels,
                type: ::Types::BranchProtections::UnprotectAccessLevelType.connection_type,
                null: true,
                description: 'Details about who can unprotect this branch.'

          field :code_owner_approval_required,
                type: GraphQL::Types::Boolean,
                null: false,
                description: 'Enforce code owner approvals before allowing a merge.'
        end
      end
    end
  end
end
