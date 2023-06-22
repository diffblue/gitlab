# frozen_string_literal: true

module Groups
  module AnalyticsDashboardHelper
    def group_analytics_dashboard_available?(group)
      Feature.enabled?(:combined_analytics_dashboards, group) &&
        group.licensed_feature_available?(:group_level_analytics_dashboard) &&
        can?(current_user, :read_group_analytics_dashboards, group)
    end
  end
end
