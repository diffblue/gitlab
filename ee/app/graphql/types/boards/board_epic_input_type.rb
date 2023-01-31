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

      argument :or, Types::Epics::UnionedEpicFilterInputType,
               required: false,
               description: 'List of arguments with inclusive OR.'

      argument :search, GraphQL::Types::String,
               required: false,
               description: 'Search query for epic title or description.'

      argument :confidential, GraphQL::Types::Boolean,
               required: false,
               description: 'Filter by confidentiality.'
    end
  end
end
