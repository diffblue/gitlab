# frozen_string_literal: true

module Groups
  module AnalyticsDashboardHelper
    def group_analytics_dashboard_available?(group)
      can?(current_user, :read_group_analytics_dashboards, group)
    end
  end
end
