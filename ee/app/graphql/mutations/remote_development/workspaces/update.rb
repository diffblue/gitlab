# frozen_string_literal: true

module Mutations
  module RemoteDevelopment
    module Workspaces
      class Update < BaseMutation
        graphql_name 'WorkspaceUpdate'

        authorize :update_workspace

        field :workspace,
          Types::RemoteDevelopment::WorkspaceType,
          null: true,
          description: 'Created workspace.'

        argument :id, ::Types::GlobalIDType[::RemoteDevelopment::Workspace],
          required: true,
          description: copy_field_description(Types::RemoteDevelopment::WorkspaceType, :id)

        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409772 - Make this a type:enum
        argument :desired_state,
          GraphQL::Types::String,
          required: true, # NOTE: This is required, because it is the only mutable field.
          description: 'Desired state of the created workspace.'

        def resolve(id:, **args)
          unless Feature.enabled?(:remote_development_feature_flag)
            raise_resource_not_available_error!("'remote_development_feature_flag' feature flag is disabled")
          end

          unless License.feature_available?(:remote_development)
            raise_resource_not_available_error!("'remote_development' licensed feature is not available")
          end

          workspace = authorized_find!(id: id)

          service = ::RemoteDevelopment::Workspaces::UpdateService.new(current_user: current_user)
          response = service.execute(workspace: workspace, params: args)

          response_object = response.success? ? response.payload[:workspace] : nil

          {
            workspace: response_object,
            errors: response.errors
          }
        end

        private

        def find_object(id:)
          GitlabSchema.find_by_gid(id)
        end
      end
    end
  end
end
