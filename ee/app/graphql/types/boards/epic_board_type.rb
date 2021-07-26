# frozen_string_literal: true

module Types
  module Boards
    class EpicBoardType < BaseObject
      graphql_name 'EpicBoard'
      description 'Represents an epic board'

      accepts ::Boards::EpicBoard
      authorize :read_epic_board

      present_using ::Boards::EpicBoardPresenter

      field :id, type: ::Types::GlobalIDType[::Boards::EpicBoard], null: false,
            description: 'Global ID of the epic board.'

      field :name, type: GraphQL::Types::String, null: true,
            description: 'Name of the epic board.'

      field :hide_backlog_list, type: GraphQL::Types::Boolean, null: true,
            description: 'Whether or not backlog list is hidden.'

      field :hide_closed_list, type: GraphQL::Types::Boolean, null: true,
            description: 'Whether or not closed list is hidden.'

      field :labels, ::Types::LabelType.connection_type, null: true,
            description: 'Labels of the board.'

      field :lists,
            Types::Boards::EpicListType.connection_type,
            null: true,
            description: 'Epic board lists.',
            extras: [:lookahead],
            resolver: Resolvers::Boards::EpicListsResolver

      field :web_path, GraphQL::Types::String, null: false,
            description: 'Web path of the epic board.'

      field :web_url, GraphQL::Types::String, null: false,
            description: 'Web URL of the epic board.'
    end
  end
end
