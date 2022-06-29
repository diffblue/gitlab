# frozen_string_literal: true

module Types
  class IterationStateEnum < BaseEnum
    graphql_name 'IterationState'
    description 'State of a GitLab iteration'

    value 'upcoming', description: 'Upcoming iteration.'
    value 'current', description: 'Current iteration.'
    value 'opened', description: 'Open iteration.'
    value 'closed', description: 'Closed iteration.'
    value 'all', description: 'Any iteration.'
  end
end
