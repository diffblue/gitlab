# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class UnassignSecurityPolicyProject < BaseMutation
      graphql_name 'SecurityPolicyProjectUnassign'
      description 'Unassigns the security policy project for the given project (`full_path`).'

      include FindsProjectOrGroupForSecurityPolicies

      authorize :update_security_orchestration_policy_project

      argument :full_path, GraphQL::Types::String,
               required: false,
               description: 'Full path of the project or group.'

      argument :project_path, GraphQL::Types::ID,
               required: false,
               deprecated: { reason: 'Use `fullPath`', milestone: '14.10' },
               description: 'Full path of the project.'

      def resolve(args)
        project_or_group = authorized_find!(**args)

        result = unassign(project_or_group)
        {
          errors: result.success? ? [] : [result.message]
        }
      end

      private

      def unassign(project_or_group)
        ::Security::Orchestration::UnassignService
          .new(container: project_or_group, current_user: current_user)
          .execute
      end
    end
  end
end
