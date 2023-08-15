# frozen_string_literal: true
class Groups::Security::DashboardController < Groups::ApplicationController
  include GovernUsageGroupTracking

  layout 'group'

  feature_category :vulnerability_management
  urgency :low
  track_govern_activity 'security_dashboard', :show, conditions: :dashboard_available?

  def show
    render :unavailable unless dashboard_available?
  end

  private

  def dashboard_available?
    can?(current_user, :read_group_security_dashboard, group)
  end
end
