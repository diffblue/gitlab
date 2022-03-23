# frozen_string_literal: true

# This class provides current status of Shared Runners minutes usage for a namespace
# taking in consideration the monthly minutes allowance that Gitlab.com provides and
# any possible purchased minutes.

module Ci
  module Minutes
    class Quota
      include Gitlab::Utils::StrongMemoize

      attr_reader :namespace, :limit

      def initialize(namespace, tracking_strategy: nil)
        @namespace = namespace
        @limit = ::Ci::Minutes::Limit.new(namespace)
        # TODO: remove `tracking_strategy` after `ci_use_new_monthly_minutes` feature flag
        # https://gitlab.com/gitlab-org/gitlab/-/issues/341730
        @tracking_strategy = tracking_strategy
      end

      def enabled?
        limit.enabled?
      end

      def minutes_used_up?
        enabled? && total_minutes_used >= limit.total
      end

      def percent_total_minutes_remaining
        return 0 unless limit.enabled?

        100 * total_minutes_remaining.to_i / limit.total
      end

      def current_balance
        limit.total - total_minutes_used
      end

      def total_minutes_used
        strong_memoize(:total_minutes_used) do
          conditional_value(
            when_new_strategy:    -> { current_usage.amount_used.to_i },
            when_legacy_strategy: -> { namespace.namespace_statistics&.shared_runners_seconds.to_i / 60 }
          )
        end
      end

      def reset_date
        strong_memoize(:reset_date) do
          conditional_value(
            when_new_strategy:    -> { current_usage.date },
            when_legacy_strategy: -> { namespace.namespace_statistics&.shared_runners_seconds_last_reset }
          )
        end
      end

      # === private to view ===
      def monthly_minutes_used_up?
        return false unless enabled?

        monthly_minutes_used >= limit.monthly
      end

      def monthly_minutes_used
        total_minutes_used - purchased_minutes_used
      end

      def purchased_minutes_used_up?
        return false unless enabled?

        limit.any_purchased? && purchased_minutes_used >= limit.purchased
      end

      def purchased_minutes_used
        return 0 if !limit.any_purchased? || monthly_minutes_available?

        total_minutes_used - limit.monthly
      end

      private

      def current_usage
        @current_usage ||= ::Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace_id: namespace.id)
      end

      def monthly_minutes_available?
        total_minutes_used <= limit.monthly
      end

      def total_minutes_remaining
        [current_balance, 0].max
      end

      def conditional_value(when_new_strategy:, when_legacy_strategy:)
        if @tracking_strategy == :new
          when_new_strategy.call
        elsif @tracking_strategy == :legacy
          when_legacy_strategy.call
        else
          when_new_strategy.call
        end
      end
    end
  end
end
