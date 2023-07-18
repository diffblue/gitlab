# frozen_string_literal: true

module Projects
  module Analytics
    class DashboardsController < Projects::ApplicationController
      include ProductAnalyticsTracking

      feature_category :product_analytics

      before_action :dashboards_enabled!, only: [:index]
      before_action :authorize_read_combined_project_analytics_dashboards!
      before_action do
        push_frontend_feature_flag(:combined_analytics_dashboards_editor, project)
      end
      before_action :track_usage, only: [:index], if: :viewing_single_dashboard?

      def index; end

      private

      def dashboards_enabled!
        render_404 unless ::Feature.enabled?(:combined_analytics_dashboards, project) &&
          project.licensed_feature_available?(:combined_project_analytics_dashboards)
      end

      def viewing_single_dashboard?
        params[:vueroute].present?
      end

      def track_usage
        ::Gitlab::UsageDataCounters::ProductAnalyticsCounter.count(:view_dashboard)

        ::Gitlab::UsageDataCounters::HLLRedisCounter.track_usage_event(
          'user_visited_dashboard',
          current_user.id
        )
      end
    end
  end
end
