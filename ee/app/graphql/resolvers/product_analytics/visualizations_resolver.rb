# frozen_string_literal: true

module Resolvers
  module ProductAnalytics
    class VisualizationsResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      calls_gitaly!
      authorizes_object!
      authorize :developer_access
      type [::Types::ProductAnalytics::VisualizationType], null: true

      argument :slug, GraphQL::Types::String, required: false, description: 'Slug of the visualization to return.'

      def resolve(slug: nil)
        visualizations = ::ProductAnalytics::Visualization.for_project(object)

        return visualizations if slug.blank?

        visualizations.select { |v| v.slug == slug }
      end
    end
  end
end
