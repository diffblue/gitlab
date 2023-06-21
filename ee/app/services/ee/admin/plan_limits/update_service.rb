# frozen_string_literal: true

module EE
  module Admin
    module PlanLimits
      module UpdateService
        extend ::Gitlab::Utils::Override

        RESTRICTED_ATTRIBUTES = %i[notification_limit enforcement_limit dashboard_limit_enabled_at].freeze

        private

        override :parsed_params
        def parsed_params
          params.except!(*RESTRICTED_ATTRIBUTES) if plan.paid?

          params
        end
      end
    end
  end
end
