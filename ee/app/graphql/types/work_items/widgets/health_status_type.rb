# frozen_string_literal: true

module Types
  module WorkItems
    module Widgets
      # rubocop:disable Graphql/AuthorizeTypes
      class HealthStatusType < BaseObject
        graphql_name 'WorkItemWidgetHealthStatus'
        description 'Represents a health status widget'

        implements Types::WorkItems::WidgetInterface

        field :health_status,
              ::Types::HealthStatusEnum,
              null: true,
              description: 'Health status of the work item.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
