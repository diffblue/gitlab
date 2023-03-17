# frozen_string_literal: true

class Groups::InsightsController < Groups::ApplicationController
  include InsightsActions
  include ProductAnalyticsTracking

  before_action :authorize_read_group!
  before_action :authorize_read_insights_config_project!

  track_event :show,
    name: 'g_analytics_insights',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  feature_category :value_stream_management

  urgency :low

  private

  def authorize_read_group!
    render_404 unless can?(current_user, :read_group, group)
  end

  def authorize_read_insights_config_project!
    insights_config_project = group.insights_config_project

    render_404 if insights_config_project && !can?(current_user, :read_project, insights_config_project)
  end

  def insights_entity
    group
  end

  def tracking_namespace_source
    group
  end

  def tracking_project_source
    nil
  end
end
