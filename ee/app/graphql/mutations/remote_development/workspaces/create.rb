# frozen_string_literal: true

module Mutations
  module RemoteDevelopment
    module Workspaces
      # noinspection RubyMismatchedArgumentType
      class Create < BaseMutation
        graphql_name 'WorkspaceCreate'

        authorize :create_workspace

        field :workspace,
          Types::RemoteDevelopment::WorkspaceType,
          null: true,
          description: 'Created workspace.'

        argument :cluster_agent_id,
          ::Types::GlobalIDType[::Clusters::Agent],
          required: true,
          description: 'ID of the cluster agent the created workspace will be associated with.'

        # TODO: https://gitlab.com/gitlab-org/gitlab/-/issues/409772 - Make this a type:enum
        argument :desired_state,
          GraphQL::Types::String,
          required: true,
          description: 'Desired state of the created workspace.'

        argument :editor,
          GraphQL::Types::String,
          required: true,
          description: 'Editor to inject into the created workspace. Must match a configured template.'

        argument :max_hours_before_termination,
          GraphQL::Types::Int,
          required: true,
          description: 'Maximum hours the workspace can exist before it is automatically terminated.'

        argument :project_id,
          ::Types::GlobalIDType[::Project],
          required: true,
          description: 'ID of the project that will provide the Devfile for the created workspace.'

        argument :devfile_ref,
          GraphQL::Types::String,
          required: true,
          description: 'Project repo git ref containing the devfile used to configure the workspace.'

        argument :devfile_path,
          GraphQL::Types::String,
          required: true,
          description: 'Project repo git path containing the devfile used to configure the workspace.'

        def resolve(args)
          unless Feature.enabled?(:remote_development_feature_flag)
            raise_resource_not_available_error!("'remote_development_feature_flag' feature flag is disabled")
          end

          unless License.feature_available?(:remote_development)
            raise_resource_not_available_error!("'remote_development' licensed feature is not available")
          end

          project_id = args.delete(:project_id)
          project = authorized_find!(id: project_id)

          cluster_agent_id = args.delete(:cluster_agent_id)

          agent = authorized_find!(id: cluster_agent_id)

          service = ::RemoteDevelopment::Workspaces::CreateService.new(current_user: current_user)
          params = args.merge(agent: agent, user: current_user, project: project)
          response = service.execute(params: params)

          response_object = response.success? ? response.payload[:workspace] : nil

          {
            workspace: response_object,
            errors: response.errors
          }
        end
      end
    end
  end
end
