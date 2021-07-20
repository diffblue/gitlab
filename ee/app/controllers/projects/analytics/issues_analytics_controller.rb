# frozen_string_literal: true

class Projects::Analytics::IssuesAnalyticsController < Projects::ApplicationController
  include IssuableCollections
  include RedisTracking

  before_action :authorize_read_issue_analytics!

  track_redis_hll_event :show, name: 'p_analytics_issues'

  feature_category :planning_analytics

  def show
    respond_to do |format|
      format.html

      format.json do
        @chart_data = if Feature.enabled?(:new_issues_analytics_chart_data, project.namespace)
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
