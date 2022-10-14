# frozen_string_literal: true

module EE
  module Projects
    module ProductAnalyticsController
      extend ActiveSupport::Concern
      extend ::Gitlab::Utils::Override

      prepended do
        before_action :dashboards_enabled!, only: [:dashboards]
      end

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
end
