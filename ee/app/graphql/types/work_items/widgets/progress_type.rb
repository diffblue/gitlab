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

        field :updated_at, Types::TimeType,
          null: true, description: 'Timestamp of last progress update.'

        field :current_value, GraphQL::Types::Int,
          null: true, description: 'Current value of the work item.'

        field :start_value, GraphQL::Types::Int,
          null: true, description: 'Start value of the work item.'

        field :end_value, GraphQL::Types::Int,
          null: true, description: 'End value of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
