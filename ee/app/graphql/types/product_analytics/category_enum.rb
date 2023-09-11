# frozen_string_literal: true

# rubocop:disable Graphql/AuthorizeTypes
module Types
  module ProductAnalytics
    class CategoryEnum < BaseEnum
      graphql_name 'CustomizableDashboardCategory'
      description 'Categories for customizable dashboards.'

      value 'ANALYTICS', value: 'analytics', description: 'Analytics category for customizable dashboards.'
    end
  end
end
# rubocop:enable Graphql/AuthorizeTypes
