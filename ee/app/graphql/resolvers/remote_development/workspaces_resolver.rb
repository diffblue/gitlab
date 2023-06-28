# frozen_string_literal: true

module Resolvers
  module RemoteDevelopment
    class WorkspacesResolver < ::Resolvers::BaseResolver
      include ResolvesIds
      include Gitlab::Graphql::Authorize::AuthorizeResource

      type Types::RemoteDevelopment::WorkspaceType.connection_type, null: true

      argument :ids, [::Types::GlobalIDType[::RemoteDevelopment::Workspace]],
        required: false,
        description:
          'Array of global workspace IDs. For example, `["gid://gitlab/RemoteDevelopment::Workspace/1"]`.'

      argument :project_ids, [::Types::GlobalIDType[Project]],
        required: false,
        description: 'Filter workspaces by project id.'

      argument :include_actual_states, [GraphQL::Types::String],
        required: false,
        description: 'Includes all workspaces that match any of the actual states.'

      def resolve(**args)
        unless ::Feature.enabled?(:remote_development_feature_flag)
          # noinspection RubyMismatchedArgumentType
          raise_resource_not_available_error! "'remote_development_feature_flag' feature flag is disabled"
        end

        unless License.feature_available?(:remote_development)
          raise_resource_not_available_error! "'remote_development' licensed feature is not available"
        end

        ::RemoteDevelopment::WorkspacesFinder.new(
          current_user,
          {
            ids: resolve_ids(args[:ids]),
            project_ids: resolve_ids(args[:project_ids]),
            include_actual_states: args[:include_actual_states]
          }
        ).execute
      end
    end
  end
end
