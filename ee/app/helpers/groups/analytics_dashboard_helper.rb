# frozen_string_literal: true

module Groups
  module AnalyticsDashboardHelper
    def group_analytics_dashboard_available?(group)
      can?(current_user, :read_group_analytics_dashboards, group) &&
        group.root_ancestor.experiment_features_enabled
    end
  end
end
