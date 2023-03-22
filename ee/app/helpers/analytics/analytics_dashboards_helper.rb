# frozen_string_literal: true

module Analytics
  module AnalyticsDashboardsHelper
    def analytics_dashboards_list_app_data(project)
      product_analytics_enabled = can?(current_user, :read_product_analytics, project)

      {
        project_id: project.id,
        dashboard_project: analytics_dashboard_pointer_project(project)&.to_json,
        jitsu_key: product_analytics_enabled ? project.project_setting.jitsu_key : nil,
        collector_host: product_analytics_enabled ? collector_host : nil,
        chart_empty_state_illustration_path: image_path('illustrations/chart-empty-state.svg'),
        dashboard_empty_state_illustration_path: image_path('illustrations/security-dashboard-empty-state.svg'),
        project_full_path: project.full_path,
        features: {
          product_analytics: product_analytics_enabled?(project)
        }.to_json
      }
    end

    private

    def collector_host
      return unless ::Gitlab::CurrentSettings.jitsu_host.present?

      ::Gitlab::CurrentSettings.current_application_settings.jitsu_host.gsub(%r{(://\w+.)}, '://collector.')
    end

    def product_analytics_enabled?(project)
      all_product_analytics_application_settings_defined? &&
        ::Feature.enabled?(:product_analytics_internal_preview, project) &&
        project.licensed_feature_available?(:product_analytics) &&
        can?(current_user, :read_product_analytics, project)
    end

    def all_product_analytics_application_settings_defined?
      return false unless ::Gitlab::CurrentSettings.product_analytics_enabled?
      return false unless ::Gitlab::CurrentSettings.jitsu_host.present?
      return false unless ::Gitlab::CurrentSettings.jitsu_project_xid.present?
      return false unless ::Gitlab::CurrentSettings.jitsu_administrator_email.present?
      return false unless ::Gitlab::CurrentSettings.jitsu_administrator_password.present?
      return false unless ::Gitlab::CurrentSettings.product_analytics_clickhouse_connection_string.present?
      return false unless ::Gitlab::CurrentSettings.cube_api_base_url.present?
      return false unless ::Gitlab::CurrentSettings.cube_api_key.present?

      true
    end

    def analytics_dashboard_pointer_project(project)
      return unless project.analytics_dashboards_pointer

      pointer_project = project.analytics_dashboards_pointer.target_project

      { id: pointer_project.id, full_path: pointer_project.full_path, name: pointer_project.name }
    end
  end
end
