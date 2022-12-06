# frozen_string_literal: true

# This class is responsible for dealing with the CI minutes limits set at root namespace level.

module Ci
  module Minutes
    class Quota
      include Gitlab::Utils::StrongMemoize

      def initialize(namespace)
        @namespace = namespace
      end

      def enabled?
        namespace.root? && !unlimited?
      end

      def total
        monthly + purchased
      end

      def monthly
        (namespace.shared_runners_minutes_limit || ::Gitlab::CurrentSettings.shared_runners_minutes).to_i
      end
      strong_memoize_attr :monthly

      def purchased
        namespace.extra_shared_runners_minutes_limit.to_i
      end
      strong_memoize_attr :purchased

      def any_purchased?
        purchased > 0
      end

      def recalculate_remaining_purchased_minutes!
        return unless should_recalculate_purchased_minutes?

        # Since we reset CI minutes data lazily, we take the last known usage
        # and not necessarily the previous month data because that represents
        # last time we reset the data.
        # Jan: monthly_minutes: 1_000, purchased_minutes: 500, minutes_used: 1_200
        # Feb: no activity (no pipelines, no data read)
        # Mar: reset and update purchased minutes to (1_000 + 500 - 1_200) = 300
        previous_amount_used = Ci::Minutes::NamespaceMonthlyUsage
          .previous_usage(namespace)
          &.amount_used.to_i

        return unless previous_amount_used > 0

        # Do nothing if the namespace had not used all the monthly minutes
        return if previous_amount_used < monthly

        balance = [(total - previous_amount_used).to_i, 0].max
        namespace.update!(extra_shared_runners_minutes_limit: balance)
      end

      private

      attr_reader :namespace

      def unlimited?
        total == 0
      end

      def should_recalculate_purchased_minutes?
        enabled? && any_purchased?
      end
    end
  end
end
