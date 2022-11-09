# frozen_string_literal: true
# rubocop:disable Graphql/AuthorizeTypes
module Types
  module ProductAnalytics
    class WidgetType < BaseObject
      graphql_name 'ProductAnalyticsDashboardWidget'
      description 'Represents a product analytics dashboard widget.'

      field :title,
            type: GraphQL::Types::String,
            null: false,
            description: 'Title of the widget.'

      field :grid_attributes,
            type: GraphQL::Types::JSON,
            null: true,
            description: 'Description of the position and size of the widget.'
    end
  end
end
# rubocop:enable Graphql/AuthorizeTypes
