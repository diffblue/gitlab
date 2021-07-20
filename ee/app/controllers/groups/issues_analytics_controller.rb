# frozen_string_literal: true

class Groups::IssuesAnalyticsController < Groups::ApplicationController
  include IssuableCollections
  include RedisTracking

  before_action :authorize_read_group!
  before_action :authorize_read_issue_analytics!

  track_redis_hll_event :show, name: 'g_analytics_issues'

  feature_category :planning_analytics

  def show
    respond_to do |format|
      format.html

      format.json do
        @chart_data = if Feature.enabled?(:new_issues_analytics_chart_data, group)
                        Analytics::IssuesAnalytics.new(issues: issuables_collection, months_back: params[:months_back])
                          .monthly_counters
                      else
                        IssuablesAnalytics.new(issuables: issuables_collection, months_back: params[:months_back]).data
                      end

        render json: @chart_data
      end
    end
  end

  private

  def authorize_read_issue_analytics!
    render_404 unless group.licensed_feature_available?(:issues_analytics)
  end

  def authorize_read_group!
    render_404 unless can?(current_user, :read_group, group)
  end

  def finder_type
    IssuesFinder
  end

  def default_state
    'all'
  end

  def preload_for_collection
    nil
  end
end
