# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class CreateSecurityPolicyProject < BaseMutation
      include FindsProject

      graphql_name 'SecurityPolicyProjectCreate'

      authorize :update_security_orchestration_policy_project

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project.'

      field :project, Types::ProjectType,
            null: true,
            description: 'Security Policy Project that was created.'

      def resolve(args)
        project = authorized_find!(args[:project_path])
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(project)

        result = create_project(project)

        return { project: nil, errors: [result[:message]] } if result[:status] == :error

        {
          project: result[:policy_project],
          errors: []
        }
      end

      private

      def allowed?(project)
        Feature.enabled?(:security_orchestration_policies_configuration, project)
      end

      def create_project(project)
        ::Security::SecurityOrchestrationPolicies::ProjectCreateService
          .new(project: project, current_user: current_user)
          .execute
      end
    end
  end
end
