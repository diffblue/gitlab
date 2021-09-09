# frozen_string_literal: true

module Types
  class IssueCreationIterationWildcardIdEnum < BaseEnum
    graphql_name 'IssueCreationIterationWildcardId'
    description 'Iteration ID wildcard values for issue creation'

    value 'CURRENT', 'Current iteration.'
  end
end
