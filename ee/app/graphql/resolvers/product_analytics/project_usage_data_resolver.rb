# frozen_string_literal: true

module Resolvers
  module ProductAnalytics
    class ProjectUsageDataResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource

      authorizes_object!
      authorize :maintainer_access
      type GraphQL::Types::Int, null: true

      argument :year, GraphQL::Types::Int,
        required: false, description: 'Year for the period to return.'

      argument :month, GraphQL::Types::Int,
        required: false, description: 'Month for the period to return.'
      def resolve(year: Time.current.year, month: Time.current.month)
        object.product_analytics_events_used(year: year, month: month)
      end
    end
  end
end
