# frozen_string_literal: true

class Groups::Analytics::RepositoryAnalyticsController < Groups::Analytics::ApplicationController
  layout 'group'

  before_action -> { authorize_view_by_action!(:read_group_repository_analytics) }

  def show
    Gitlab::Tracking.event(self.class.name, 'show', **pageview_tracker_params)
  end

  private

  def pageview_tracker_params
    {
      label: 'group_id',
      value: @group.id,
      user: current_user,
      namespace: @group
    }
  end

  def build_canonical_path(group)
    url_for(safe_params.merge(group_id: group.to_param))
  end
end
