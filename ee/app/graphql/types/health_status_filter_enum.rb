# frozen_string_literal: true

module Types
  class HealthStatusFilterEnum < HealthStatusEnum
    graphql_name 'HealthStatusFilter'
    description 'Health status of an issue or epic for filtering'

    value 'NONE', description: 'No health status is assigned.', value: ::IssuableFinder::Params::FILTER_NONE
    value 'ANY', description: 'Any health status is assigned.', value: ::IssuableFinder::Params::FILTER_ANY
  end
end
