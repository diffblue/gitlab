# frozen_string_literal: true

module Projects
  module AnalyticsDashboardHelper
    def project_analytics_dashboard_available?(project)
      Feature.enabled?(:combined_analytics_dashboards, project) &&
        project.licensed_feature_available?(:project_level_analytics_dashboard) &&
        project.group
    end
  end
end
