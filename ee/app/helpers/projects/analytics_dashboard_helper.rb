# frozen_string_literal: true

module Projects
  module AnalyticsDashboardHelper
    def analytics_dashboard_available?(project)
      Feature.enabled?(:project_analytics_dashboards_page, project) &&
        project.licensed_feature_available?(:project_level_analytics_dashboard) &&
        project.group
    end
  end
end
