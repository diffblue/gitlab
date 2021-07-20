# frozen_string_literal: true

class Projects::InsightsController < Projects::ApplicationController
  include InsightsActions
  include RedisTracking

  helper_method :project_insights_config

  before_action :authorize_read_project!
  before_action :authorize_read_insights!

  track_redis_hll_event :show, name: 'p_analytics_insights'

  feature_category :insights

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
end
