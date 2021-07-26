# frozen_string_literal: true

module Types
  module Boards
    class BoardEpicInputType < BoardIssuableInputBaseType
      graphql_name 'EpicFilters'

      class NegatedEpicBoardIssueInputType < BoardIssuableInputBaseType
      end

      argument :not, NegatedEpicBoardIssueInputType,
               required: false,
               description: 'Negated epic arguments.'

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Search query for epic title or description.'
    end
  end
end
