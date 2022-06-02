# frozen_string_literal: true

module Projects
  module Security
    class DastConfigurationController < Projects::ApplicationController
      include SecurityAndCompliancePermissions
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action do
        push_frontend_feature_flag(:dast_ui_redesign, @project)
      end

      feature_category :dynamic_application_security_testing

      def show
      end
    end
  end
end
