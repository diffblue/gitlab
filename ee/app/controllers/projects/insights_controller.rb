# frozen_string_literal: true

class Projects::InsightsController < Projects::ApplicationController
  include InsightsActions
  include ProductAnalyticsTracking

  helper_method :project_insights_config

  before_action :authorize_read_project!
  before_action :authorize_read_insights!

  track_event :show,
    name: 'p_analytics_insights',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  feature_category :value_stream_management

  urgency :low

  private

  def insights_entity
    project
  end

  def config_data
    project_insights_config.filtered_config
  end

  def project_insights_config
    @project_insights_config ||= Gitlab::Insights::ProjectInsightsConfig.new(project: project, insights_config: insights_entity.insights_config)
  end

  def tracking_namespace_source
    project.namespace
  end

  def tracking_project_source
    project
  end
end
