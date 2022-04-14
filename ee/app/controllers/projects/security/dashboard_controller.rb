# frozen_string_literal: true

module Projects
  module Security
    class DashboardController < Projects::ApplicationController
      include SecurityAndCompliancePermissions
      include SecurityDashboardsPermissions

      alias_method :vulnerable, :project

      before_action only: [:index] do
        push_frontend_feature_flag(:security_auto_fix, project, default_enabled: false)
        push_frontend_feature_flag(:vulnerability_management_survey, type: :ops, default_enabled: :yaml)
      end

      feature_category :vulnerability_management
    end
  end
end
