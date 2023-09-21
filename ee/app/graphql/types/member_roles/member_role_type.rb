# frozen_string_literal: true

module Types
  module MemberRoles
    class MemberRoleType < BaseObject
      graphql_name 'MemberRole'
      description 'Represents a member role'

      authorize :read_group_member

      field :id,
        ::Types::GlobalIDType[::MemberRole],
        null: false,
        description: 'ID of the member role.'

      field :name,
        GraphQL::Types::String,
        null: false,
        description: 'Name of the member role.'

      field :description,
        GraphQL::Types::String,
        null: true,
        description: 'Description of the member role.'
    end
  end
end
