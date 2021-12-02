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

      argument :confidential, GraphQL::Types::Boolean,
               required: false,
               description: 'Filter by confidentiality.'
    end
  end
end
