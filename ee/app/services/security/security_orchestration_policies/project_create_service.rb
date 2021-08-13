# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProjectCreateService < ::BaseProjectService
      ACCESS_LEVELS_TO_ADD = [Gitlab::Access::MAINTAINER, Gitlab::Access::DEVELOPER].freeze

      def execute
        return error('Security Policy project already exists.') if project.security_orchestration_policy_configuration.present?

        policy_project = ::Projects::CreateService.new(current_user, create_project_params).execute

        return error(policy_project.errors.full_messages.join(',')) unless policy_project.saved?

        members = add_members(policy_project)
        errors = members.flat_map { |member| member.errors.full_messages }

        return error('Project was created and assigned as security policy project, but failed adding users to the project.') if errors.any?

        success(policy_project: policy_project)
      end

      private

      def add_members(policy_project)
        developers_and_maintainers = project.team.members_with_access_levels(ACCESS_LEVELS_TO_ADD)
        members_to_add = developers_and_maintainers - policy_project.team.members
        policy_project.add_users(members_to_add, :developer)
      end

      def create_project_params
        {
          visibility_level: project.visibility_level,
          security_policy_target_project_id: project.id,
          name: "#{project.name} - Security policy project",
          description: "This project is automatically generated to manage security policies for the project.",
          namespace_id: project.namespace.id,
          initialize_with_readme: true,
          container_registry_enabled: false,
          packages_enabled: false,
          requirements_enabled: false,
          builds_enabled: false,
          wiki_enabled: false,
          snippets_enabled: false
        }
      end

      attr_reader :project
    end
  end
end
