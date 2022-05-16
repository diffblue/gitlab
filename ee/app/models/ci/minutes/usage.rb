# frozen_string_literal: true

# This class provides current status of Shared Runners minutes usage for a namespace
# taking in consideration the monthly minutes allowance that Gitlab.com provides and
# any possible purchased minutes.

module Ci
  module Minutes
    class Usage
      include Gitlab::Utils::StrongMemoize

      attr_reader :namespace, :limit

      def initialize(namespace)
        @namespace = namespace
        @limit = ::Ci::Minutes::Limit.new(namespace)
      end

      def limit_enabled?
        limit.enabled?
      end

      def minutes_used_up?
        limit_enabled? && total_minutes_used >= limit.total
      end

      def percent_total_minutes_remaining
        return 0 unless limit_enabled?

        100 * total_minutes_remaining.to_i / limit.total
      end

      def current_balance
        limit.total - total_minutes_used
      end

      def total_minutes_used
        current_usage.amount_used.to_i
      end

      def reset_date
        current_usage.date
      end

      # === private to view ===
      def monthly_minutes_used_up?
        return false unless limit_enabled?

        monthly_minutes_used >= limit.monthly
      end

      def monthly_minutes_used
        total_minutes_used - purchased_minutes_used
      end

      def purchased_minutes_used_up?
        return false unless limit_enabled?

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
    end
  end
end
