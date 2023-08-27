# frozen_string_literal: true

module Types
  module ProductAnalytics
    class DashboardType < BaseObject
      graphql_name 'CustomizableDashboard'
      description 'Represents a product analytics dashboard.'
      authorize :developer_access

      field :title,
            type: GraphQL::Types::String,
            null: false,
            description: 'Title of the dashboard.'

      field :category,
            type: ::Types::ProductAnalytics::CategoryEnum,
            null: false,
            description: 'Category of dashboard.'

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

      field :user_defined,
            type: GraphQL::Types::Boolean,
            null: false,
            description: 'Indicates whether the dashboard is user-defined or provided by GitLab.'

      field :configuration_project,
            type: Types::ProjectType,
            method: :config_project,
            null: true,
            description: 'Project which contains the dashboard definition.'
    end
  end
end
