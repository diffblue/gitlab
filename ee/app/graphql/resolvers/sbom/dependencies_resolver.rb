# frozen_string_literal: true

module Resolvers
  module Sbom
    class DependenciesResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      authorize :read_dependencies
      authorizes_object!

      type Types::Sbom::DependencyType.connection_type, null: true

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        return ::Sbom::Occurrence.none unless project

        dependencies(args)
      end

      def preloads
        {
          name: [:component],
          version: [:component_version],
          packager: [:source],
          location: [:source]
        }
      end

      private

      def dependencies(params)
        apply_lookahead(::Sbom::DependenciesFinder.new(project, params: params).execute)
      end
    end
  end
end
