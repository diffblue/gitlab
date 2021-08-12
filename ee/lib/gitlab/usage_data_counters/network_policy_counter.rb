# frozen_string_literal: true

module Gitlab::UsageDataCounters
  class NetworkPolicyCounter < BaseCounter
    KNOWN_EVENTS = %w[forwards drops].freeze
    PREFIX = 'network_policy'

    class << self
      def add(forwards, drops)
        return unless ::ServicePing::ServicePingSettings.enabled?

        Gitlab::Redis::SharedState.with do |redis|
          redis.multi do
            redis.incrby(redis_key(:forwards), forwards)
            redis.incrby(redis_key(:drops), drops)
          end
        end
      end
    end
  end
end
