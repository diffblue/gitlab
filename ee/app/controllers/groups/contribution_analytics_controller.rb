# frozen_string_literal: true

class Groups::ContributionAnalyticsController < Groups::ApplicationController
  include ProductAnalyticsTracking

  before_action :group
  before_action :authorize_read_contribution_analytics!

  layout 'group'

  track_event :show,
    name: 'g_analytics_contribution',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  feature_category :value_stream_management
  urgency :low

  def show
    @start_date = data_collector.from

    respond_to do |format|
      format.html
      format.json do
        render json: GroupAnalyticsSerializer
          .new(data_collector: data_collector)
          .represent(data_collector.users), status: :ok
      end
    end
  end

  private

  def data_collector
    @data_collector ||= Gitlab::ContributionAnalytics::DataCollector
      .new(group: @group, from: from_date(params[:start_date]))
  end

  def authorize_read_contribution_analytics!
    render_404 unless group_has_access_to_feature? && user_has_access_to_feature?
  end

  def show_promotions?
    LicenseHelper.show_promotions?(current_user)
  end

  def group_has_access_to_feature?
    @group.licensed_feature_available?(:contribution_analytics)
  end

  def user_has_access_to_feature?
    can?(current_user, :read_group_contribution_analytics, @group)
  end

  def from_date(value)
    Date.parse(value)
  rescue Date::Error, TypeError
    1.week.ago.to_date
  end

  def tracking_namespace_source
    @group
  end

  def tracking_project_source
    nil
  end
end
