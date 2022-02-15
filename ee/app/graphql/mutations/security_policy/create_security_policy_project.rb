# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class CreateSecurityPolicyProject < BaseMutation
      graphql_name 'SecurityPolicyProjectCreate'
      description 'Creates and assigns a security policy project for the given project(`project_path`)'

      include FindsProject

      authorize :update_security_orchestration_policy_project

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project.'

      field :project, Types::ProjectType,
            null: true,
            description: 'Security Policy Project that was created.'

      def resolve(args)
        project = authorized_find!(args[:project_path])

        result = create_project(project)
        return { project: nil, errors: [result[:message]] } if result[:status] == :error

        {
          project: result[:policy_project],
          errors: []
        }
      end

      private

      def create_project(project)
        ::Security::SecurityOrchestrationPolicies::ProjectCreateService
          .new(project: project, current_user: current_user)
          .execute
      end
    end
  end
end
