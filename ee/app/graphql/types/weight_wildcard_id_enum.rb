# frozen_string_literal: true

module Types
  class WeightWildcardIdEnum < BaseEnum
    graphql_name 'WeightWildcardId'
    description 'Weight ID wildcard values'

    value 'NONE', 'No weight is assigned.'
    value 'ANY', 'Weight is assigned.'
  end
end
