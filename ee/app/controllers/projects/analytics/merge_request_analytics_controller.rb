# frozen_string_literal: true

class Projects::Analytics::MergeRequestAnalyticsController < Projects::ApplicationController
  include ProductAnalyticsTracking

  before_action :authorize_read_project_merge_request_analytics!

  track_event :show,
    name: 'p_analytics_merge_request',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  feature_category :value_stream_management
  urgency :low

  def show
  end

  def tracking_namespace_source
    project.namespace
  end

  def tracking_project_source
    project
  end
end
