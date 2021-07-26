# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class CodeCoverageActivityType < BaseObject
      graphql_name 'CodeCoverageActivity'
      description 'Represents the code coverage activity for a group'

      field :average_coverage, GraphQL::FLOAT_TYPE, null: true,
            description: 'Average percentage of the different code coverage results available for the group.'

      field :coverage_count, GraphQL::Types::Int, null: true,
            description: 'Number of different code coverage results available for the group.'

      field :project_count, GraphQL::Types::Int, null: true,
            description: 'Number of projects with code coverage results for the group.'

      field :date, Types::DateType, null: false,
            description: 'Date when the code coverage was created.'
    end
  end
end
