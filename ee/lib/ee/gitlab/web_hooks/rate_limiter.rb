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

        override :rate_limit!
        def rate_limit!
          is_over_limit = super

          # In this first iteration of paid plan webhook rate-limiting,
          # only log but allow the webhook to execute.
          if is_over_limit && paid_plan?
            log_is_over_limit!
            return false
          end

          is_over_limit
        end

        override :rate_limited?
        def rate_limited?
          return false if no_limit? || paid_plan?

          super
        end

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

        # Log at most once per minute (the same interval as webhook rate-limiting).
        def log_is_over_limit!
          ::Gitlab::ExclusiveLease.throttle(root_namespace.id, period: 1.minute) do
            ::Gitlab::AppLogger.info(
              {
                message: 'Webhook rate limit would be exceeded',
                hook_id: hook.id,
                hook_type: hook.type,
                root_namespace: root_namespace.full_path_components.first,
                plan: plan.name,
                limit: limit,
                limit_name: limit_name
              }
            )
          end
        end
      end
    end
  end
end
