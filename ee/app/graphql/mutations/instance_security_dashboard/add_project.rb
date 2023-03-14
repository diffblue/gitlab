# frozen_string_literal: true

module Mutations
  module InstanceSecurityDashboard
    class AddProject < BaseMutation
      graphql_name 'AddProjectToSecurityDashboard'

      authorize :add_project_to_instance_security_dashboard

      field :project, Types::ProjectType,
            null: true,
            description: 'Project that was added to the Instance Security Dashboard.'

      argument :id, ::Types::GlobalIDType[::Project],
               required: true,
               description: 'ID of the project to be added to Instance Security Dashboard.'

      def resolve(id:)
        project = authorized_find!(id: id)
        result = add_project(project)
        error_message = prepare_error_message(result, project)

        {
          project: error_message ? nil : project,
          errors: [error_message].compact
        }
      end

      private

      def add_project(project)
        Dashboard::Projects::CreateService
          .new(current_user, current_user.security_dashboard_projects, ability: :read_security_resource)
          .execute([project.id])
      end

      def prepare_error_message(result, project)
        return if result.added_project_ids.include?(project.id)

        if result.duplicate_project_ids.include?(project.id)
          _('The project has already been added to your dashboard.')
        elsif result.not_licensed_project_ids.include?(project.id)
          _('Only projects created under a Ultimate license are available in Security Dashboards.')
        else
          _('Project was not found or you do not have permission to add this project to Security Dashboards.')
        end
      end
    end
  end
end
