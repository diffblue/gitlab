# frozen_string_literal: true

class Groups::Analytics::DevopsAdoptionController < Groups::Analytics::ApplicationController
  include ProductAnalyticsTracking

  layout 'group'

  before_action -> { authorize_view_by_action!(:view_group_devops_adoption) }

  track_event :show,
    name: 'users_viewing_analytics_group_devops_adoption',
    action: 'perform_analytics_usage_action',
    label: 'redis_hll_counters.analytics.analytics_total_unique_counts_monthly',
    destinations: %i[redis_hll snowplow]

  def show
  end

  def tracking_namespace_source
    @group
  end

  def tracking_project_source
    nil
  end
end
