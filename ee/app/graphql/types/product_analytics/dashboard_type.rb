# frozen_string_literal: true

module Types
  module ProductAnalytics
    class DashboardType < BaseObject
      graphql_name 'ProductAnalyticsDashboard'
      description 'Represents a product analytics dashboard.'
      authorize :developer_access

      field :title,
            type: GraphQL::Types::String,
            null: false,
            description: 'Title of the dashboard.'

      field :description,
            type: GraphQL::Types::String,
            null: true,
            description: 'Description of the dashboard.'

      field :widgets,
            type: Types::ProductAnalytics::WidgetType.connection_type,
            null: false,
            description: 'Widgets shown on the dashboard.'
    end
  end
end
