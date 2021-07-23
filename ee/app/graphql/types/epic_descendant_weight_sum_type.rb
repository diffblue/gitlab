# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class EpicDescendantWeightSumType < BaseObject
    graphql_name 'EpicDescendantWeights'
    description 'Total weight of open and closed descendant issues'

    field :opened_issues, GraphQL::Types::Int, null: true,
          description: 'Total weight of opened issues in this epic, including epic descendants.'
    field :closed_issues, GraphQL::Types::Int, null: true,
          description: 'Total weight of completed (closed) issues in this epic, including epic descendants.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
