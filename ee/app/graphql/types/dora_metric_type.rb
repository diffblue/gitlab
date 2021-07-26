# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class DoraMetricType < BaseObject
    graphql_name 'DoraMetric'

    field :date, GraphQL::Types::String, null: true,
          description: 'Date of the data point.'
    field :value, GraphQL::Types::Int, null: true,
          description: 'Value of the data point.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
