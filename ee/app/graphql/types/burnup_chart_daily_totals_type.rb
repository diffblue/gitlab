# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class BurnupChartDailyTotalsType < BaseObject
    graphql_name 'BurnupChartDailyTotals'
    description 'Represents the total number of issues and their weights for a particular day'

    field :date, GraphQL::Types::ISO8601Date,
      null: false, description: 'Date for burnup totals.'

    field :scope_count, GraphQL::Types::Int,
      null: false, description: 'Number of issues as of this day.'

    field :scope_weight, GraphQL::Types::Int,
      null: false, description: 'Total weight of issues as of this day.'

    field :completed_count, GraphQL::Types::Int,
      null: false, description: 'Number of closed issues as of this day.'

    field :completed_weight, GraphQL::Types::Int,
      null: false, description: 'Total weight of closed issues as of this day.'
  end
end
