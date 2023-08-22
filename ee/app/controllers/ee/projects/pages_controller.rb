# frozen_string_literal: true

module EE
  module Projects
    module PagesController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      override :project_params_attributes
      def project_params_attributes
        return super unless can?(current_user, :update_max_pages_size)

        super + %i[max_pages_size]
      end

      override :project_setting_attributes
      def project_setting_attributes
        return super unless can?(current_user, :pages_multiple_versions, project)

        super + %i[pages_multiple_versions_enabled]
      end
    end
  end
end
