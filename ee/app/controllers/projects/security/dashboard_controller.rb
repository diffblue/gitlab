# frozen_string_literal: true

module Projects
  module Security
    class DashboardController < Projects::ApplicationController
      include SecurityAndCompliancePermissions
      include SecurityDashboardsPermissions
      include GovernUsageProjectTracking

      alias_method :vulnerable, :project

      before_action only: [:index] do
        push_frontend_feature_flag(:security_auto_fix, project)
      end

      feature_category :vulnerability_management
      urgency :low
      track_govern_activity 'security_dashboard', :index
    end
  end
end
