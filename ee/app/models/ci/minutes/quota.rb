# frozen_string_literal: true

# This class provides current status of Shared Runners minutes usage for a namespace
# taking in consideration the monthly minutes allowance that Gitlab.com provides and
# any possible purchased minutes.

module Ci
  module Minutes
    class Quota
      include Gitlab::Utils::StrongMemoize

      attr_reader :namespace

      def initialize(namespace)
        @namespace = namespace
      end

      def enabled?
        namespace_root? && !namespace_unlimited_minutes?
      end

      def minutes_used_up?
        enabled? && total_minutes_used >= total_minutes
      end

      def percent_total_minutes_remaining
        return 0 if total_minutes == 0

        100 * total_minutes_remaining.to_i / total_minutes
      end

      def current_balance
        total_minutes.to_i - total_minutes_used
      end

      def total_minutes
        strong_memoize(:total_minutes) do
          monthly_minutes + purchased_minutes
        end
      end

      def total_minutes_used
        strong_memoize(:total_minutes_used) do
          # TODO: use namespace.new_monthly_ci_minutes_enabled? to switch to
          # ::Ci::Minutes::NamespaceMonthlyUsage.find_or_create_current(namespace.id).amount_used.to_i
          namespace.namespace_statistics&.shared_runners_seconds.to_i / 60
        end
      end

      def purchased_minutes
        strong_memoize(:purchased_minutes) do
          namespace.extra_shared_runners_minutes_limit.to_i
        end
      end

      def namespace_root?
        strong_memoize(:namespace_root) do
          namespace.root?
        end
      end

      def namespace_unlimited_minutes?
        total_minutes.to_i == 0
      end

      def monthly_minutes
        strong_memoize(:monthly_minutes) do
          (namespace.shared_runners_minutes_limit || ::Gitlab::CurrentSettings.shared_runners_minutes).to_i
        end
      end

      # === private to view ===
      def monthly_minutes_used_up?
        return false unless enabled?

        monthly_minutes_used >= monthly_minutes
      end

      def monthly_minutes_used
        total_minutes_used - purchased_minutes_used
      end

      def purchased_minutes_used_up?
        return false unless enabled?

        any_minutes_purchased? && purchased_minutes_used >= purchased_minutes
      end

      def purchased_minutes_used
        return 0 if no_minutes_purchased? || monthly_minutes_available?

        total_minutes_used - monthly_minutes
      end

      private

      def monthly_minutes_available?
        total_minutes_used <= monthly_minutes
      end

      def no_minutes_purchased?
        purchased_minutes == 0
      end

      def any_minutes_purchased?
        purchased_minutes > 0
      end

      def total_minutes_remaining
        [current_balance, 0].max
      end
    end
  end
end
