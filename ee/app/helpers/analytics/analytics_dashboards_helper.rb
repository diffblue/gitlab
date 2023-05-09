# frozen_string_literal: true

module Analytics
  module AnalyticsDashboardsHelper
    def analytics_dashboards_list_app_data(project)
      can_read_product_analytics = can?(current_user, :read_product_analytics, project)

      {
        project_id: project.id,
        dashboard_project: analytics_dashboard_pointer_project(project)&.to_json,
        tracking_key: can_read_product_analytics ? tracking_key(project) : nil,
        collector_host: can_read_product_analytics ? collector_host : nil,
        chart_empty_state_illustration_path: image_path('illustrations/chart-empty-state.svg'),
        dashboard_empty_state_illustration_path: image_path('illustrations/security-dashboard-empty-state.svg'),
        project_full_path: project.full_path,
        features: enabled_analytics_features(project).to_json,
        router_base: project_analytics_dashboards_path(project)
      }
    end

    private

    def collector_host
      ::Gitlab::CurrentSettings.product_analytics_data_collector_host
    end

    def tracking_key(project)
      return project.project_setting.jitsu_key unless ::Feature.enabled?(:product_analytics_snowplow_support)

      project.project_setting.product_analytics_instrumentation_key || project.project_setting.jitsu_key
    end

    def enabled_analytics_features(project)
      [].tap do |features|
        features << :product_analytics if product_analytics_enabled?(project)
      end
    end

    def product_analytics_enabled?(project)
      ProductAnalytics::Settings.for_project(project).enabled? &&
        ::Feature.enabled?(:product_analytics_dashboards, project) &&
        project.licensed_feature_available?(:product_analytics) &&
        can?(current_user, :read_product_analytics, project)
    end

    def analytics_dashboard_pointer_project(project)
      return unless project.analytics_dashboards_pointer

      pointer_project = project.analytics_dashboards_pointer.target_project

      { id: pointer_project.id, full_path: pointer_project.full_path, name: pointer_project.name }
    end
  end
end
