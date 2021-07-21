# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class EpicDescendantCountType < BaseObject
    graphql_name 'EpicDescendantCount'
    description 'Counts of descendent epics'

    field :opened_epics, GraphQL::Types::Int, null: true, description: 'Number of opened child epics.'
    field :closed_epics, GraphQL::Types::Int, null: true, description: 'Number of closed child epics.'
    field :opened_issues, GraphQL::Types::Int, null: true, description: 'Number of opened epic issues.'
    field :closed_issues, GraphQL::Types::Int, null: true, description: 'Number of closed epic issues.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
