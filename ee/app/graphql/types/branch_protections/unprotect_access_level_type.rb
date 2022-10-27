# frozen_string_literal: true

module Types
  module BranchProtections
    class UnprotectAccessLevelType < BaseAccessLevelType # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'UnprotectAccessLevel'
      description 'Defines which user roles, users, or groups can unprotect a protected branch.'
      accepts ::ProtectedBranch::UnprotectAccessLevel
    end
  end
end
