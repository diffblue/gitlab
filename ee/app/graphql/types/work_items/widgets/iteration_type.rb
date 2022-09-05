# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class IterationType < BaseObject
        graphql_name 'WorkItemWidgetIteration'
        description 'Represents an iteration widget'

        implements Types::WorkItems::WidgetInterface

        field :iteration,
              ::Types::IterationType,
              null: true,
              description: 'Iteration of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
