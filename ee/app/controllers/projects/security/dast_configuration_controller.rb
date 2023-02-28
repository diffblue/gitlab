# frozen_string_literal: true

module Projects
  module Security
    class DastConfigurationController < Projects::ApplicationController
      include SecurityAndCompliancePermissions
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action do
        push_frontend_feature_flag(:dast_pre_scan_verification, @project)
      end

      feature_category :dynamic_application_security_testing
      urgency :low, [:show]

      def show
      end
    end
  end
end
