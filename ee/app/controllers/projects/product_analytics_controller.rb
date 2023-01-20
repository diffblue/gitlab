# frozen_string_literal: true

module Projects
  class ProductAnalyticsController < Projects::ApplicationController
    feature_category :product_analytics

    before_action :dashboards_enabled!, only: [:dashboards]
    before_action :authorize_read_product_analytics!

    def dashboards; end

    private

    def dashboards_enabled!
      render_404 unless all_application_settings_defined? &&
        ::Feature.enabled?(:product_analytics_internal_preview, project) &&
        project.licensed_feature_available?(:product_analytics)
    end

    def all_application_settings_defined?
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
