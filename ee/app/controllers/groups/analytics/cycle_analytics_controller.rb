# frozen_string_literal: true

class Groups::Analytics::CycleAnalyticsController < Groups::Analytics::ApplicationController
  include CycleAnalyticsParams
  include ProductAnalyticsTracking
  extend ::Gitlab::Utils::Override

  increment_usage_counter Gitlab::UsageDataCounters::CycleAnalyticsCounter, :views, only: :show

  before_action :load_project, only: :show
  before_action :load_value_stream, only: :show
  before_action :request_params, only: :show

  before_action do
    push_licensed_feature(:group_level_analytics_dashboard) if group_feature?(:group_level_analytics_dashboard)
    render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
  end

  layout 'group'

  track_event :show,
    name: 'g_analytics_valuestream',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.g_analytics_valuestream_monthly',
    destinations: [:redis_hll, :snowplow]

  def show
  end

  private

  def namespace
    @group
  end

  override :all_cycle_analytics_params
  def all_cycle_analytics_params
    super.merge({ value_stream: @value_stream })
  end

  def load_value_stream
    return unless @group && params[:value_stream_id]

    default_name = Analytics::CycleAnalytics::Stages::BaseService::DEFAULT_VALUE_STREAM_NAME

    @value_stream = if params[:value_stream_id] == default_name
                      @group.value_streams.new(name: default_name)
                    else
                      @group.value_streams.find(params[:value_stream_id])
                    end
  end

  alias_method :tracking_namespace_source, :load_group
  alias_method :tracking_project_source, :load_project

  def group_feature?(feature)
    @group.licensed_feature_available?(feature)
  end
end
