# frozen_string_literal: true

class Groups::InsightsController < Groups::ApplicationController
  include InsightsActions
  include RedisTracking

  before_action :authorize_read_group!
  before_action :authorize_read_insights_config_project!

  track_redis_hll_event :show, name: 'g_analytics_insights'

  feature_category :insights

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
end
