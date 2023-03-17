# frozen_string_literal: true

module Projects
  module Analytics
    class CodeReviewsController < Projects::ApplicationController
      include ProductAnalyticsTracking

      before_action :authorize_read_code_review_analytics!

      track_event :index,
        name: 'p_analytics_code_reviews',
        action: 'perform_analytics_usage_action',
        label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
        destinations: %i[redis_hll snowplow]

      feature_category :value_stream_management
      urgency :low

      def index
      end

      def tracking_namespace_source
        project.namespace
      end

      def tracking_project_source
        project
      end
    end
  end
end
