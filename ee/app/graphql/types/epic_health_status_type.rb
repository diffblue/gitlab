# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class EpicHealthStatusType < BaseObject
    graphql_name 'EpicHealthStatus'
    description 'Health status of child issues'

    field :issues_on_track, GraphQL::Types::Int, null: true, description: 'Number of issues on track.'
    field :issues_needing_attention, GraphQL::Types::Int, null: true, description: 'Number of issues that need attention.'
    field :issues_at_risk, GraphQL::Types::Int, null: true, description: 'Number of issues at risk.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
