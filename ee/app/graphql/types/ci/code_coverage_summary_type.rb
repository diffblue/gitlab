# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class CodeCoverageSummaryType < BaseObject
      graphql_name 'CodeCoverageSummary'
      description 'Represents the code coverage summary for a project'

      field :average_coverage, GraphQL::FLOAT_TYPE, null: true,
            description: 'Average percentage of the different code coverage results available for the project.'

      field :coverage_count, GraphQL::Types::Int, null: true,
            description: 'Number of different code coverage results available.'

      field :last_updated_on, Types::DateType, null: true,
            description: 'Latest date when the code coverage was created for the project.'
    end
  end
end
