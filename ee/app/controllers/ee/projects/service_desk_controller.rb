# frozen_string_literal: true

module EE
  module Projects
    module ServiceDeskController
      extend ::Gitlab::Utils::Override

      protected

      override :allowed_update_attributes
      def allowed_update_attributes
        super + %i[file_template_project_id]
      end

      override :service_desk_attributes
      def service_desk_attributes
        service_desk_settings = project.service_desk_setting

        super.merge(file_template_project_id: service_desk_settings&.file_template_project_id)
      end
    end
  end
end
