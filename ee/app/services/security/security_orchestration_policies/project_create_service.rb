# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProjectCreateService < ::BaseContainerService
      ACCESS_LEVELS_TO_ADD = [Gitlab::Access::MAINTAINER, Gitlab::Access::DEVELOPER].freeze
      README_TEMPLATE_PATH = Rails.root.join('ee', 'app', 'views', 'projects', 'security', 'policies', 'readme.md.tt')

      def execute
        return error(s_('User does not have permission to create a Security Policy project.')) unless can_create_projects_in_container?
        return error(s_('Security Policy project already exists.')) if container.security_orchestration_policy_configuration.present?

        policy_project = ::Projects::CreateService.new(current_user, create_project_params).execute

        return error(policy_project.errors.full_messages.join(',')) unless policy_project.saved?

        if project_container?
          members = add_members(policy_project)
          errors = members.flat_map { |member| member.errors.full_messages }

          return error(s_('Project was created and assigned as security policy project, but failed adding users to the project.')) if errors.any?
        end

        success(policy_project: policy_project)
      end

      private

      def add_members(policy_project)
        members_to_add = developers_and_maintainers - policy_project.team.members
        policy_project.add_members(members_to_add, :developer) || []
      end

      def developers_and_maintainers
        container.team.members_with_access_levels(ACCESS_LEVELS_TO_ADD)
      end

      def create_project_params
        {
          creator: current_user,
          visibility_level: container.visibility_level,
          name: "#{container.name} - Security policy project",
          description: "This project is automatically generated to manage security policies for the project.",
          namespace_id: namespace_id,
          initialize_with_readme: true,
          container_registry_enabled: false,
          packages_enabled: false,
          requirements_enabled: false,
          builds_enabled: false,
          wiki_enabled: false,
          snippets_enabled: false,
          readme_template: readme_template
        }.merge(security_policy_target_id)
      end

      def security_policy_target_id
        if project_container?
          { security_policy_target_project_id: container.id }
        elsif namespace_container?
          { security_policy_target_namespace_id: container.id }
        end
      end

      def namespace_id
        if project_container?
          container.namespace_id
        elsif namespace_container?
          container.id
        end
      end

      def readme_template
        ERB.new(File.read(README_TEMPLATE_PATH), trim_mode: '<>').result(binding)
      end

      def can_create_projects_in_container?
        current_user.can?(:create_projects, project_container? ? container.namespace : container)
      end
    end
  end
end
