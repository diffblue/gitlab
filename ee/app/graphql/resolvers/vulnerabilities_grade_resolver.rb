# frozen_string_literal: true

module Resolvers
  class VulnerabilitiesGradeResolver < VulnerabilitiesBaseResolver
    type [::Types::VulnerableProjectsByGradeType], null: true

    argument :include_subgroups, GraphQL::Types::Boolean,
              required: false,
              default_value: false,
              description: 'Include grades belonging to subgroups.'

    def resolve(**args)
      ::Gitlab::Graphql::Aggregations::VulnerabilityStatistics::LazyAggregate
        .new(context, vulnerable, include_subgroups: args[:include_subgroups])
    end
  end
end
