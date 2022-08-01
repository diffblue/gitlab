# frozen_string_literal: true

module Types
  module Boards
    # rubocop: disable Graphql/AuthorizeTypes
    class BoardEpicType < EpicType
      graphql_name 'BoardEpic'
      description 'Represents an epic on an issue board'

      field :user_preferences,
            Types::Boards::EpicUserPreferencesType,
            null: true,
            description: 'User preferences for the epic on the issue board.'

      def user_preferences
        return unless current_user

        board = context[:board]
        raise ::Gitlab::Graphql::Errors::BaseError 'Board is not set' unless board

        BatchLoader::GraphQL.for(object.id).batch(key: board) do |epic_ids, loader, args|
          current_user
            .boards_epic_user_preferences
            .for_boards_and_epics(args[:key].id, epic_ids)
            .each { |user_pref| loader.call(user_pref.epic_id, user_pref) }
        end
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
