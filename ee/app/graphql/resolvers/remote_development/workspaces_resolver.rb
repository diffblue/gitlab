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

      def resolve(**args)
        unless ::Feature.enabled?(:remote_development_feature_flag)
          # noinspection RubyMismatchedArgumentType
          raise ::Gitlab::Graphql::Errors::ResourceNotAvailable,
            "'remote_development_feature_flag' feature flag is disabled"
        end

        unless License.feature_available?(:remote_development)
          raise_resource_not_available_error! "'remote_development' licensed feature is not available"
        end

        ::RemoteDevelopment::WorkspacesFinder.new(
          current_user,
          { ids: resolve_ids(args[:ids]) }
        ).execute
      end
    end
  end
end
