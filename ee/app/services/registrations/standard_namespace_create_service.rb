# frozen_string_literal: true

module Registrations
  class StandardNamespaceCreateService < BaseNamespaceCreateService
    def execute
      if new_group?
        create_with_new_group_flow
      else
        @group = Group.find_by_id(existing_group_id)

        create_project_flow
      end
    end

    private

    def new_group?
      !existing_group_id
    end

    def existing_group_id
      params.dig(:group, :id)
    end

    def create_with_new_group_flow
      @group = Groups::CreateService.new(user, modified_group_params).execute

      if group.persisted?
        after_successful_group_creation(group_track_action: 'create_group')
        create_project_flow
      else
        @project = Project.new(project_params)

        ServiceResponse.error(message: 'Group failed to be created', payload: { group: group, project: project })
      end
    end

    def create_project_params
      project_params(:initialize_with_readme)
    end

    def project_params(*extra)
      params.require(:project).permit(project_params_attributes + extra).merge(namespace_id: group.id)
    end

    def project_params_attributes
      [
        :namespace_id,
        :name,
        :path,
        :visibility_level
      ]
    end

    def create_project_flow
      @project = ::Projects::CreateService.new(user, create_project_params).execute

      if project.persisted?
        Gitlab::Tracking.event(self.class.name, 'create_project', namespace: project.namespace, user: user)

        ServiceResponse.success(payload: { project: project })
      else
        ServiceResponse.error(message: 'Project failed to be created', payload: { group: group, project: project })
      end
    end
  end
end

Registrations::StandardNamespaceCreateService.prepend_mod
