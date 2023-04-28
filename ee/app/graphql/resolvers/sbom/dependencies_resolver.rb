# frozen_string_literal: true

module Resolvers
  module Sbom
    class DependenciesResolver < BaseResolver
      include Gitlab::Graphql::Authorize::AuthorizeResource
      include LooksAhead

      SORT_TO_PARAMS_MAP = {
        name_desc: { sort_by: 'name', sort: 'desc' },
        name_asc: { sort_by: 'name', sort: 'asc' },
        packager_desc: { sort_by: 'packager', sort: 'desc' },
        packager_asc: { sort_by: 'packager', sort: 'asc' }
      }.freeze

      authorize :read_dependencies
      authorizes_object!

      type Types::Sbom::DependencyType.connection_type, null: true

      argument :sort, Types::Sbom::DependencySortEnum,
        required: false,
        description: 'Sort dependencies by given criteria.'

      alias_method :project, :object

      def resolve_with_lookahead(**args)
        return ::Sbom::Occurrence.none unless project

        list = dependencies(args)

        offset_pagination(list)
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
        apply_lookahead(::Sbom::DependenciesFinder.new(project, params: mapped_params(params)).execute)
      end

      def mapped_params(params)
        return SORT_TO_PARAMS_MAP.fetch(params[:sort], {}) if params[:sort]

        {}
      end
    end
  end
end
