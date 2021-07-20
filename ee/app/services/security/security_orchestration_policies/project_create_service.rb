# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProjectCreateService < ::BaseProjectService
      def execute
        return error('Security Policy project already exists.') if project.security_orchestration_policy_configuration.present?

        policy_project = ::Projects::CreateService.new(current_user, create_project_params).execute

        return error(policy_project.errors.full_messages.join(',')) unless policy_project.saved?

        project.create_security_orchestration_policy_configuration! do |p|
          p.security_policy_management_project_id = policy_project.id
        end
        create_or_update_protected_branch(policy_project)

        members = add_members(policy_project)
        errors = members.flat_map { |member| member.errors.full_messages }

        return error('Project was created and assigned as security policy project, but failed adding users to the project.') if errors.any?

        success(policy_project: policy_project)
      end

      private

      def create_or_update_protected_branch(policy_project)
        protected_branch = policy_project.protected_branches.find_by_name(policy_project.default_branch_or_main)
        params = {
          name: policy_project.default_branch_or_main,
          push_access_levels_attributes: [{ access_level: Gitlab::Access::NO_ACCESS }],
          merge_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
        }

        if protected_branch.present?
          ProtectedBranches::UpdateService
            .new(policy_project, current_user, params)
            .execute(protected_branch)
          return
        end

        ProtectedBranches::CreateService
          .new(policy_project, current_user, params)
          .execute(skip_authorization: true)
      end

      def add_members(policy_project)
        members_to_add = project.team.maintainers - policy_project.team.members
        policy_project.add_users(members_to_add, :developer)
      end

      def create_project_params
        {
          visibility_level: project.visibility_level,
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
