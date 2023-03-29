# frozen_string_literal: true

module EE
  module Admin
    module PlanLimitsController
      extend ActiveSupport::Concern

      prepended do
        skip_before_action :set_plan_limits, only: :index
      end

      def index
        return not_found unless ::Feature.enabled?(:plan_limits_admin_dashboard, current_user)
        return not_found unless ::Gitlab::CurrentSettings.should_check_namespace_plan?
      end
    end
  end
end
