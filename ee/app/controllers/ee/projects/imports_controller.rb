# frozen_string_literal: true

module EE
  module Projects
    module ImportsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      private

      override :require_namespace_project_creation_permission
      def require_namespace_project_creation_permission
        render_404 unless can?(current_user, :admin_project, project) ||
          can?(current_user, :import_projects, project.namespace) ||
          (can?(current_user, :create_projects, project.namespace) &&
          project.gitlab_custom_project_template_import?)
      end

      override :import_params_attributes
      def import_params_attributes
        super + [:mirror]
      end

      override :import_params
      def import_params
        super.merge(mirror_user_id: current_user&.id)
      end
    end
  end
end
