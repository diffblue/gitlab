# frozen_string_literal: true

class Projects::Analytics::MergeRequestAnalyticsController < Projects::ApplicationController
  include RedisTracking

  before_action :authorize_read_project_merge_request_analytics!

  track_redis_hll_event :show, name: 'p_analytics_merge_request'

  feature_category :planning_analytics

  def show
  end
end
