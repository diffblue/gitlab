# frozen_string_literal: true

module Groups
  module Security
    class VulnerabilitiesController < Groups::ApplicationController
      include GovernUsageGroupTracking

      layout 'group'

      before_action do
        push_frontend_feature_flag(:expose_dismissal_reason, @project)
      end

      feature_category :vulnerability_management
      urgency :low
      track_govern_activity 'security_vulnerabilities', :index, conditions: :dashboard_available?

      def index
        render :unavailable unless dashboard_available?
      end

      private

      def dashboard_available?
        can?(current_user, :read_group_security_dashboard, group)
      end
    end
  end
end
