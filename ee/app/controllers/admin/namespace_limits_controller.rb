# frozen_string_literal: true

module Admin
  class NamespaceLimitsController < Admin::ApplicationController
    feature_category :consumables_cost_management
    urgency :low

    before_action :check_gitlab_com

    def index; end

    private

    def check_gitlab_com
      not_found unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
    end
  end
end
