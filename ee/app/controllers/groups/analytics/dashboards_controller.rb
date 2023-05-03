# frozen_string_literal: true

module Groups
  module Analytics
    class DashboardsController < Groups::Analytics::ApplicationController
      include ProductAnalyticsTracking

      track_event :value_streams_dashboard,
        name: 'g_metrics_comparison_page',
        action: 'perform_analytics_usage_action',
        label: 'redis_hll_counters.analytics.g_metrics_comparison_page_monthly',
        destinations: %i[redis_hll snowplow]

      before_action { authorize_view_by_action!(:read_group_analytics_dashboards) }

      layout 'group'

      MAX_ALLOWED_PATHS = 4

      def index
        # Value streams dashboard has been moved into another action,
        # this is a temporary redirect to keep current bookmarks healthy.
        redirect_to(value_streams_dashboard_group_analytics_dashboards_path(@group, query: params[:query]))
      end

      def value_streams_dashboard
        @pointer_project = find_pointer_project

        @namespaces =
          if params[:query].present?
            paths_array = params[:query].split(",").first(MAX_ALLOWED_PATHS)
            sources = Route.inside_path(@group.full_path).where(path: paths_array).map(&:source) # rubocop:disable CodeReuse/ActiveRecord

            sources.map do |source|
              {
                name: source.name,
                full_path: source.full_path,
                is_project: project?(source)
              }
            end
          else
            []
          end

        Gitlab::UsageDataCounters::ValueStreamsDashboardCounter.count(:views)
      end

      private

      def find_pointer_project
        Project.find_by_id(
          @group.analytics_dashboards_pointer&.target_project_id
        )&.as_json(only: %w[id name], methods: %w[full_path])
      end

      def project?(source)
        source.model_name.param_key == "project"
      end

      def tracking_namespace_source
        @group
      end

      def tracking_project_source
        nil
      end
    end
  end
end
