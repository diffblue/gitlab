# frozen_string_literal: true

module Types
  module Dora
    # rubocop: disable Graphql/AuthorizeTypes
    class PerformanceScoreCountType < BaseObject
      graphql_name 'DoraPerformanceScoreCount'
      description 'Aggregated DORA score counts for projects for the last complete month.'

      field :metric_name, GraphQL::Types::String,
        null: false,
        description: 'Name of the DORA metric.'

      field :low_projects_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of projects that score "low" on the metric.'

      field :medium_projects_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of projects that score "medium" on the metric.'

      field :high_projects_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of projects that score "high" on the metric.'

      field :no_data_projects_count, GraphQL::Types::Int,
        null: true,
        description: 'Number of projects with no data.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
