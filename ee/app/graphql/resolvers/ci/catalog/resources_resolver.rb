# frozen_string_literal: true

module Resolvers
  module Ci
    module Catalog
      class ResourcesResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource
        include ResolvesProject

        authorize :read_namespace_catalog

        type ::Types::Ci::Catalog::ResourceType.connection_type, null: true

        argument :project_path, GraphQL::Types::ID,
          required: false,
          description: 'Project with the namespace catalog.'

        def resolve(project_path:)
          project = authorized_find!(project_path: project_path)

          ::Ci::Catalog::Listing.new(project.root_namespace, context[:current_user]).resources
        end

        private

        def find_object(project_path:)
          resolve_project(full_path: project_path)
        end
      end
    end
  end
end
