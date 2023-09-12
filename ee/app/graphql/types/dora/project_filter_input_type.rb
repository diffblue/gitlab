# frozen_string_literal: true

module Types
  module Dora
    class ProjectFilterInputType < BaseInputObject
      graphql_name 'DoraProjectFilterInput'
      description 'Filter parameters for projects to be aggregated for DORA metrics.'

      argument :topic, type: [GraphQL::Types::String],
        required: false,
        description: 'Filter projects by topic.'
    end
  end
end
