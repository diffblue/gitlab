# frozen_string_literal: true

module Types
  module AccessLevels
    class GroupType < BaseObject
      graphql_name 'AccessLevelGroup'
      description 'Representation of a GitLab group.'

      authorize :read_group

      field :id,
        type: GraphQL::Types::ID,
        null: false,
        description: 'ID of the group.'

      field :name,
        type: GraphQL::Types::String,
        null: false,
        description: 'Name of the group.'

      field :web_url,
        type: GraphQL::Types::String,
        null: false,
        description: 'Web URL of the group.'

      field :avatar_url,
        type: GraphQL::Types::String,
        null: true,
        description: 'Avatar URL of the group.'

      field :parent,
        type: AccessLevels::GroupType,
        null: true,
        description: 'Parent group.'

      def avatar_url
        object.avatar_url(only_path: false)
      end
    end
  end
end
