# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # Disabling widget level authorization as it might be too granular
      # and we already authorize the parent work item
      # rubocop:disable Graphql/AuthorizeTypes
      class ProgressType < BaseObject
        graphql_name 'WorkItemWidgetProgress'
        description 'Represents a progress widget'

        implements Types::WorkItems::WidgetInterface

        field :progress, GraphQL::Types::Int,
          null: true, description: 'Progress of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
