# frozen_string_literal: true

# rubocop:disable Graphql/AuthorizeTypes
module Types
  module ProductAnalytics
    class PanelType < BaseObject
      graphql_name 'ProductAnalyticsDashboardPanel'
      description 'Represents a product analytics dashboard panel.'

      field :title,
        type: GraphQL::Types::String,
        null: false,
        description: 'Title of the panel.'

      field :grid_attributes,
        type: GraphQL::Types::JSON,
        null: true,
        description: 'Description of the position and size of the panel.'

      field :visualization,
        type: Types::ProductAnalytics::VisualizationType,
        null: false,
        description: 'Visualization of the panel.',
        resolver: Resolvers::ProductAnalytics::VisualizationResolver
    end
  end
end
# rubocop:enable Graphql/AuthorizeTypes
