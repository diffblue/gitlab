# frozen_string_literal: true

module EE
  module Gitlab
    module WebHooks
      module RateLimiter
        extend ::Gitlab::Utils::Override

        LOW_RATE_LIMIT = :web_hook_calls_low
        MID_RATE_LIMIT = :web_hook_calls_mid
        HIGH_RATE_LIMIT = ::Gitlab::WebHooks::RateLimiter::LIMIT_NAME

        PREMIUM_MID_RANGE = (100..399).freeze
        ULTIMATE_MID_RANGE = (1_000..4_999).freeze

        LIMIT_MAP = {
          Plan::BRONZE => PREMIUM_MID_RANGE,
          Plan::SILVER => PREMIUM_MID_RANGE,
          Plan::GOLD => ULTIMATE_MID_RANGE,
          Plan::PREMIUM => PREMIUM_MID_RANGE,
          Plan::PREMIUM_TRIAL => PREMIUM_MID_RANGE,
          Plan::ULTIMATE => ULTIMATE_MID_RANGE,
          Plan::ULTIMATE_TRIAL => ULTIMATE_MID_RANGE,
          Plan::OPEN_SOURCE => ULTIMATE_MID_RANGE
        }.freeze

        private

        override :limit_name
        def limit_name
          strong_memoize(:ee_limit_name) do
            next super unless paid_plan?

            # Limits for paid plans are stepped based on the number of seats
            # for the customer.
            case seats.clamp(LIMIT_MAP[plan.name]) <=> seats
            when -1 then HIGH_RATE_LIMIT
            when 0 then MID_RATE_LIMIT
            when 1 then LOW_RATE_LIMIT
            end
          end
        end

        def paid_plan?
          plan.paid?
        end

        def plan
          @plan ||= root_namespace.actual_plan
        end

        def seats
          @seats ||= root_namespace.gitlab_subscription.seats
        end
      end
    end
  end
end
