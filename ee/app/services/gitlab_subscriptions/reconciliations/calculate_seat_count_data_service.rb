# frozen_string_literal: true
#
module GitlabSubscriptions
  module Reconciliations
    class CalculateSeatCountDataService
      include Gitlab::Utils::StrongMemoize

      # For smaller groups we want to alert when they have a set quantity of seats remaining.
      # For larger groups we want to alert them when they have a percentage of seats remaining.
      SEAT_COUNT_THRESHOLD_LIMITS = [
        { range: (0..15), percentage: false, value: 1 },
        { range: (16..25), percentage: false, value: 2 },
        { range: (26..99), percentage: true, value: 10 },
        { range: (100..999), percentage: true, value: 8 },
        { range: (1000..nil), percentage: true, value: 5 }
      ].freeze

      attr_reader :namespace, :user

      delegate :max_seats_used, :max_seats_used_changed_at, :seats, :seats_remaining, to: :current_subscription

      def initialize(namespace:, user:)
        @namespace = namespace
        @user = user
      end

      def execute
        return unless owner_of_paid_group? && seat_count_threshold_reached?
        return if max_seats_used_changed_at.nil? || user_dismissed_alert?
        return unless alert_user_overage?

        {
          namespace: namespace,
          remaining_seat_count: seats_remaining,
          seats_in_use: max_seats_used,
          total_seat_count: seats
        }
      end

      private

      def owner_of_paid_group?
        (::Gitlab::CurrentSettings.should_check_namespace_plan? &&
          namespace.group_namespace? &&
          user.can?(:admin_group, namespace) &&
          current_subscription).present?
      end

      def adapted_remaining_user_count
        return seats_remaining.fdiv(seats) * 100 if current_seat_count_threshold[:percentage]

        seats_remaining
      end

      def alert_user_overage?
        CheckSeatUsageAlertsEligibilityService.new(namespace: namespace).execute
      end

      def current_subscription
        strong_memoize(:current_subscription) do
          subscription = namespace.gitlab_subscription

          subscription if subscription&.has_a_paid_hosted_plan? && !subscription.expired?
        end
      end

      def current_seat_count_threshold
        strong_memoize(:current_seat_count_threshold) do
          SEAT_COUNT_THRESHOLD_LIMITS.find do |threshold|
            threshold[:range].cover?(seats)
          end
        end
      end

      def seat_count_threshold_reached?
        max_seats_used &&
          max_seats_used < seats &&
          current_seat_count_threshold[:value] >= adapted_remaining_user_count
      end

      def user_dismissed_alert?
        user.dismissed_callout_for_group?(
          feature_name: Users::GroupCalloutsHelper::APPROACHING_SEAT_COUNT_THRESHOLD,
          group: namespace,
          ignore_dismissal_earlier_than: max_seats_used_changed_at
        )
      end
    end
  end
end
