# frozen_string_literal: true

module Mutations
  module InstanceSecurityDashboard
    class RemoveProject < BaseMutation
      graphql_name 'RemoveProjectFromSecurityDashboard'

      authorize :read_instance_security_dashboard

      argument :id, Types::GlobalIDType[::Project],
               required: true,
               description: 'ID of the project to remove from the Instance Security Dashboard.'

      def resolve(id:)
        dashboard = authorized_find!
        raise_resource_not_available_error! unless dashboard.feature_available?(:security_dashboard)

        result = remove_project(extract_project_id(id))

        {
          errors: result == 0 ? ['The project does not belong to your dashboard or you don\'t have permission to perform this action'] : []
        }
      end

      private

      def find_object(*args)
        ::InstanceSecurityDashboard.new(current_user)
      end

      def extract_project_id(gid)
        gid&.model_id
      end

      def remove_project(project_id)
        current_user
          .users_security_dashboard_projects
          .delete_by_project_id(project_id)
      end
    end
  end
end
