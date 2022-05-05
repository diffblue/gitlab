# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class CreateSecurityPolicyProject < BaseMutation
      graphql_name 'SecurityPolicyProjectCreate'
      description 'Creates and assigns a security policy project for the given project (`full_path`)'

      include FindsProjectOrGroupForSecurityPolicies

      authorize :update_security_orchestration_policy_project

      argument :full_path, GraphQL::Types::String,
               required: false,
               description: 'Full path of the project or group.'

      argument :project_path, GraphQL::Types::ID,
               required: false,
               deprecated: { reason: 'Use `fullPath`', milestone: '14.10' },
               description: 'Full path of the project.'

      field :project, Types::ProjectType,
            null: true,
            description: 'Security Policy Project that was created.'

      def resolve(args)
        project_or_group = authorized_find!(**args)

        result = create_project(project_or_group)
        return { project: nil, errors: [result[:message]] } if result[:status] == :error

        {
          project: result[:policy_project],
          errors: []
        }
      end

      private

      def create_project(project_or_group)
        ::Security::SecurityOrchestrationPolicies::ProjectCreateService
          .new(container: project_or_group, current_user: current_user)
          .execute
      end
    end
  end
end
