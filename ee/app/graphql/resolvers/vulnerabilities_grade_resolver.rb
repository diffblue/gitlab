# frozen_string_literal: true

module Resolvers
  class VulnerabilitiesGradeResolver < VulnerabilitiesBaseResolver
    authorize :read_security_resource
    authorizes_object!

    type [::Types::VulnerableProjectsByGradeType], null: true

    argument :include_subgroups, GraphQL::Types::Boolean,
              required: false,
              default_value: false,
              description: 'Include grades belonging to subgroups.'

    argument :letter_grade, Types::VulnerabilityGradeEnum,
             required: false,
             description: "Filter the response by given letter grade."

    def resolve(**args)
      authorize!
      ::Gitlab::Graphql::Aggregations::VulnerabilityStatistics::LazyAggregate
        .new(context, vulnerable, filter: args[:letter_grade], include_subgroups: args[:include_subgroups])
    end

    def authorize!
      Ability.allowed?(context[:current_user], :read_security_resource, vulnerable) ||
        raise_resource_not_available_error!
    end
  end
end
