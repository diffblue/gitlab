# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class UnassignSecurityPolicyProject < BaseMutation
      graphql_name 'SecurityPolicyProjectUnassign'
      description 'Unassigns the security policy project for the given project(`project_path`).'

      include FindsProject

      authorize :update_security_orchestration_policy_project

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project.'

      def resolve(args)
        project = authorized_find!(args[:project_path])

        result = unassign_project(project)
        {
          errors: result.success? ? [] : [result.message]
        }
      end

      private

      def unassign_project(project)
        ::Security::Orchestration::UnassignService
          .new(project, current_user)
          .execute
      end
    end
  end
end
