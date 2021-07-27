# frozen_string_literal: true

module Projects
  module Security
    class DastConfigurationController < Projects::ApplicationController
      include SecurityAndCompliancePermissions
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      feature_category :dynamic_application_security_testing

      def show
      end
    end
  end
end
