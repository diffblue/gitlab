# frozen_string_literal: true

module Analytics
  module AnalyticsDashboardsHelper
    def analytics_dashboards_list_app_data(namespace)
      is_project = project?(namespace)
      can_read_product_analytics = can?(current_user, :read_product_analytics, namespace)

      {
        namespace_id: namespace.id,
        dashboard_project: analytics_dashboard_pointer_project(namespace)&.to_json,
        tracking_key: can_read_product_analytics && is_project ? tracking_key(namespace) : nil,
        collector_host: can_read_product_analytics ? collector_host : nil,
        chart_empty_state_illustration_path: image_path('illustrations/chart-empty-state.svg'),
        dashboard_empty_state_illustration_path: image_path('illustrations/security-dashboard-empty-state.svg'),
        namespace_full_path: namespace.full_path,
        features: is_project ? enabled_analytics_features(namespace).to_json : [].to_json,
        router_base: router_base(namespace)
      }
    end

    def analytics_project_settings_data(project)
      can_read_product_analytics = can?(current_user, :read_product_analytics, project)

      {
        tracking_key: can_read_product_analytics ? tracking_key(project) : nil,
        collector_host: can_read_product_analytics ? collector_host : nil,
        dashboards_path: project_analytics_dashboards_path(project)
      }
    end

    private

    def project?(namespace)
      namespace.is_a?(Project)
    end

    def collector_host
      ::Gitlab::CurrentSettings.product_analytics_data_collector_host
    end

    def tracking_key(project)
      project.project_setting.product_analytics_instrumentation_key
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

    def analytics_dashboard_pointer_project(namespace)
      return unless namespace.analytics_dashboards_pointer

      pointer_project = namespace.analytics_dashboards_pointer.target_project

      { id: pointer_project.id, full_path: pointer_project.full_path, name: pointer_project.name }
    end

    def router_base(namespace)
      return project_analytics_dashboards_path(namespace) if project?(namespace)

      group_analytics_dashboards_path(namespace)
    end
  end
end
