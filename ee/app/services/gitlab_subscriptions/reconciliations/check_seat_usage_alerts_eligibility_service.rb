# frozen_string_literal: true

# Service to determine if the given namespace meets the criteria to see
# alert usage overage alerts when they cross the usage thresholds.
# This service only determines eligibility from the CustomersDot application.
#
# If there is a problem querying CustomersDot, it assumes the status is false
#
# returns true, false
module GitlabSubscriptions
  module Reconciliations
    class CheckSeatUsageAlertsEligibilityService
      def initialize(namespace:, skip_cached: false)
        @namespace = namespace
        @skip_cached = skip_cached
      end

      def execute
        return false unless namespace.gitlab_subscription.present?

        skip_cached ? eligible_for_seat_usage_alerts_request : eligible_for_seat_usage_alerts
      end

      private

      attr_reader :namespace, :skip_cached

      def client
        Gitlab::SubscriptionPortal::Client
      end

      def eligible_for_seat_usage_alerts_request
        response = client.subscription_seat_usage_alerts_eligibility(namespace.id)

        return false unless response[:success]

        response[:eligible_for_seat_usage_alerts] || false
      end

      def cache
        Rails.cache
      end

      def cache_key
        "subscription:eligible_for_seat_usage_alerts:namespace:#{namespace.gitlab_subscription.cache_key}"
      end

      def eligible_for_seat_usage_alerts
        cache.fetch(cache_key, expires_in: 1.day) { eligible_for_seat_usage_alerts_request }
      end
    end
  end
end
