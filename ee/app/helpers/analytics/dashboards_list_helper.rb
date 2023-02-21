# frozen_string_literal: true

module Analytics
  module DashboardsListHelper
    def analytics_dashboards_list_app_data(project)
      {
        project_id: project.id,
        jitsu_key: project.project_setting.jitsu_key,
        jitsu_host: Gitlab::CurrentSettings.current_application_settings.jitsu_host,
        jitsu_project_id: Gitlab::CurrentSettings.current_application_settings.jitsu_project_xid,
        chart_empty_state_illustration_path: image_path('illustrations/chart-empty-state.svg'),
        project_full_path: project.full_path,
        router_base: project_analytics_dashboards_path(project),
        features: {
          product_analytics: product_analytics_enabled?(project)
        }.to_json
      }
    end

    private

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
  end
end
