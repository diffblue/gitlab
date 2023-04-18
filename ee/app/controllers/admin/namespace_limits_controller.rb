# frozen_string_literal: true

module Admin
  class NamespaceLimitsController < Admin::ApplicationController
    feature_category :consumables_cost_management
    urgency :low

    before_action :check_dashboard_enabled
    before_action :check_gitlab_com

    def index; end

    private

    def check_gitlab_com
      not_found unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
    end

    def check_dashboard_enabled
      not_found unless ::Feature.enabled?(:namespace_limits_admin_dashboard, current_user)
    end
  end
end
