# frozen_string_literal: true

module Gitlab
  module EtagCaching
    module Router
      Route = Struct.new(:regexp, :name, :feature_category, :router) do
        delegate :match, to: :regexp
        delegate :cache_key, to: :router
      end

      module Helpers
        def build_route(attrs)
          EtagCaching::Router::Route.new(*attrs, self)
        end

        def build_rails_route(attrs)
          regexp, name, controller, action_name = *attrs
          EtagCaching::Router::Route.new(
            regexp,
            name,
            controller.feature_category_for_action(action_name).to_s,
            self
          )
        end
      end

      # Performing Rails routing match before GraphQL would be more expensive
      # for the GraphQL requests because we need to traverse all of the RESTful
      # route definitions before falling back to GraphQL.
      def self.match(request)
        Router::Graphql.match(request) || Router::Rails.match(request)
      end
    end
  end
end
