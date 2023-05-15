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

      field :slug,
            type: GraphQL::Types::String,
            null: false,
            description: 'Slug of the dashboard.'

      field :description,
            type: GraphQL::Types::String,
            null: true,
            description: 'Description of the dashboard.'

      field :panels,
            type: Types::ProductAnalytics::PanelType.connection_type,
            null: false,
            description: 'Panels shown on the dashboard.'
    end
  end
end
