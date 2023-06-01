# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class ResourcesResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource
        include ResolvesProject
        include LooksAhead

        authorize :read_namespace_catalog

        type ::Types::Ci::Catalog::ResourceType.connection_type, null: true

        argument :sort, ::Types::Ci::Catalog::ResourceSortEnum,
          required: false,
          description: 'Sort Catalog Resources by given criteria.'

        argument :project_path, GraphQL::Types::ID,
          required: false,
          description: 'Project with the namespace catalog.'

        def resolve_with_lookahead(project_path:, sort: nil)
          project = authorized_find!(project_path: project_path)

          apply_lookahead(
            ::Ci::Catalog::Listing.new(project.root_namespace, context[:current_user]).resources(sort: sort)
          )
        end

        private

        def find_object(project_path:)
          resolve_project(full_path: project_path)
        end

        def preloads
          {
            web_path: { project: { namespace: :route } },
            readme_html: { project: :route }
          }
        end
      end
    end
  end
end
