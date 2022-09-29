# frozen_string_literal: true

module Types
  module ProtectedEnvironments
    # This type is authorized in the parent entity.
    # rubocop:disable Graphql/AuthorizeTypes
    class AuthorizableType < BaseObject
      field :user, ::Types::UserType,
            description: "User details. Present if it's user specific access control."

      field :group, '::Types::GroupType',
            description: "Group details. Present if it's group specific access control."

      field :access_level, ::Types::AccessLevelType,
            description: "Role details. Present if it's role specific access control."
    end
    # rubocop:enable Graphql/AuthorizeTypes
  end
end
