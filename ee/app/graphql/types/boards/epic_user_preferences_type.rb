# frozen_string_literal: true

module Types
  module Boards
    # rubocop: disable Graphql/AuthorizeTypes
    class EpicUserPreferencesType < BaseObject
      graphql_name 'BoardEpicUserPreferences'
      description 'Represents user preferences for a board epic'

      field :collapsed, GraphQL::Types::Boolean, null: false,
            description: 'Indicates epic should be displayed as collapsed.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
