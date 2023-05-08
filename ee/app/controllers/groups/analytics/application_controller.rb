# frozen_string_literal: true

class Groups::Analytics::ApplicationController < ApplicationController
  include RoutableActions
  include GracefulTimeoutHandling

  feature_category :team_planning
  urgency :low

  before_action :load_group

  private

  def self.increment_usage_counter(counter_klass, counter, *args)
    before_action(*args) { counter_klass.count(counter) }
  end

  def authorize_view_by_action!(action)
    return render_403 unless can?(current_user, action, @group)
  end

  def check_feature_availability!(feature)
    return render_403 unless @group && @group.licensed_feature_available?(feature)
  end

  def load_group
    return unless params['group_id']

    @group ||= find_routable!(Group, params['group_id'], request.fullpath)
  end

  def load_project
    return unless @group && params['project_id']

    @project = find_routable!(@group.all_projects, params['project_id'], request.fullpath)
  end

  private_class_method :increment_usage_counter
end
