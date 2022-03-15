# frozen_string_literal: true

class Groups::Analytics::CycleAnalyticsController < Groups::Analytics::ApplicationController
  include CycleAnalyticsParams
  include RedisTracking
  extend ::Gitlab::Utils::Override

  increment_usage_counter Gitlab::UsageDataCounters::CycleAnalyticsCounter, :views, only: :show

  before_action :load_group, only: %I[show use_aggregated_backend]
  before_action :load_project, only: :show
  before_action :load_value_stream, only: :show
  before_action :request_params, only: :show

  before_action do
    render_403 unless can?(current_user, :read_group_cycle_analytics, @group)
  end

  layout 'group'

  track_redis_hll_event :show, name: 'g_analytics_valuestream'

  def show
    epic_link_start = '<a href="%{url}" target="_blank" rel="noopener noreferrer">'.html_safe % { url: "https://gitlab.com/groups/gitlab-org/-/epics/6046" }
    flash.now[:notice] = s_("ValueStreamAnalytics|Items in Value Stream Analytics are currently filtered by their creation time. There is an %{epic_link_start}epic%{epic_link_end} that will change the Value Stream Analytics date filter to use the end event time for the selected stage.").html_safe % { epic_link_start: epic_link_start, epic_link_end: "</a>".html_safe }
  end

  def use_aggregated_backend
    aggregation = Analytics::CycleAnalytics::Aggregation.safe_create_for_group(@group)
    aggregation.update!(enabled: params[:enabled])

    render json: { enabled: aggregation.enabled }
  end

  private

  override :all_cycle_analytics_params

  def all_cycle_analytics_params
    super.merge({ group: @group, value_stream: @value_stream })
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
end
