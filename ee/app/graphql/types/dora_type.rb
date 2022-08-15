# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class DoraType < BaseObject
    graphql_name 'Dora'
    description 'All information related to DORA metrics.'

    field :metrics, [::Types::DoraMetricType],
      null: true,
      resolver: ::Resolvers::DoraMetricsResolver,
      description: 'DORA metrics for the current group or project.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
