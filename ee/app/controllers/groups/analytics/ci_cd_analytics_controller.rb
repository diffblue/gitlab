# frozen_string_literal: true

class Groups::Analytics::CiCdAnalyticsController < Groups::Analytics::ApplicationController
  include RedisTracking

  layout 'group'

  before_action :load_group
  before_action -> { check_feature_availability!(:group_ci_cd_analytics) }
  before_action -> { authorize_view_by_action!(:view_group_ci_cd_analytics) }

  track_redis_hll_event :show, name: 'g_analytics_ci_cd_release_statistics',
    if: -> { should_track_ci_cd_release_statistics? }
  track_redis_hll_event :show, name: 'g_analytics_ci_cd_deployment_frequency',
    if: -> { should_track_ci_cd_deployment_frequency? }
  track_redis_hll_event :show, name: 'g_analytics_ci_cd_lead_time',
    if: -> { should_track_ci_cd_lead_time? }
  track_redis_hll_event :show, name: 'g_analytics_ci_cd_time_to_restore_service',
    if: -> { should_track_ci_cd_time_to_restore_service? }
  track_redis_hll_event :show, name: 'g_analytics_ci_cd_change_failure_rate',
    if: -> { should_track_ci_cd_change_failure_rate? }

  def show
  end

  def should_track_ci_cd_release_statistics?
    params[:tab].blank? || params[:tab] == 'release-statistics'
  end

  def should_track_ci_cd_deployment_frequency?
    params[:tab] == 'deployment-frequency'
  end

  def should_track_ci_cd_lead_time?
    params[:tab] == 'lead-time'
  end

  def should_track_ci_cd_time_to_restore_service?
    params[:tab] == 'time-to-restore-service'
  end

  def should_track_ci_cd_change_failure_rate?
    params[:tab] == 'change-failure-rate'
  end
end
