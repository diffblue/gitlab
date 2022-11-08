# frozen_string_literal: true

module Projects
  class ProductAnalyticsController < Projects::ApplicationController
    feature_category :product_analytics

    before_action :dashboards_enabled!, only: [:dashboards]
    before_action :authorize_read_product_analytics!

    def dashboards; end

    private

    def dashboards_enabled!
      unless ::Feature.enabled?(:product_analytics_internal_preview, project) &&
          project.licensed_feature_available?(:product_analytics)
        render_404
      end
    end
  end
end
