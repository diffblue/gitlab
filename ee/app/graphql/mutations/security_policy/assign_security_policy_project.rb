# frozen_string_literal: true

module Mutations
  module SecurityPolicy
    class AssignSecurityPolicyProject < BaseMutation
      include FindsProject

      graphql_name 'SecurityPolicyProjectAssign'

      authorize :update_security_orchestration_policy_project

      argument :project_path, GraphQL::Types::ID,
               required: true,
               description: 'Full path of the project.'

      argument :security_policy_project_id, ::Types::GlobalIDType[::Project],
               required: true,
               description: 'ID of the security policy project.'

      def resolve(args)
        project = authorized_find!(args[:project_path])
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, 'Feature disabled' unless allowed?(project)

        policy_project = find_policy_project(args[:security_policy_project_id])
        raise_resource_not_available_error! unless policy_project.present?

        result = assign_project(project, policy_project)
        {
          errors: result.success? ? [] : [result.message]
        }
      end

      private

      def find_policy_project(id)
        # TODO: remove explicit coercion once compatibility layer has been removed
        # See: https://gitlab.com/gitlab-org/gitlab/-/issues/257883
        id = ::Types::GlobalIDType[::Project].coerce_isolated_input(id)
        ::Gitlab::Graphql::Lazy.force(GitlabSchema.object_from_id(id, expected_type: Project))
      end

      def allowed?(project)
        Feature.enabled?(:security_orchestration_policies_configuration, project)
      end

      def assign_project(project, policy_project)
        ::Security::Orchestration::AssignService
          .new(project, current_user, policy_project_id: policy_project.id)
          .execute
      end
    end
  end
end
