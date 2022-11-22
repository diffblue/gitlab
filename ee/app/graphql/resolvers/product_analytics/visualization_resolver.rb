# frozen_string_literal: true

module Resolvers
  module ProductAnalytics
    class VisualizationResolver < BaseResolver
      type ::Types::ProductAnalytics::VisualizationType, null: true

      def resolve
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Visualization does not exist' unless object.visualization

        object.visualization
      end
    end
  end
end
