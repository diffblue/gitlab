# frozen_string_literal: true

module Resolvers
  module ProductAnalytics
    class DashboardsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      calls_gitaly!
      authorizes_object!
      authorize :developer_access
      type [::Types::ProductAnalytics::DashboardType], null: true

      argument :slug, GraphQL::Types::String,
               required: false,
               description: 'Find by dashboard slug.'

      def resolve(slug: nil)
        return unless object.product_analytics_enabled?
        return object.product_analytics_dashboards unless slug.present?

        [object.product_analytics_dashboard(slug)]
      end
    end
  end
end
