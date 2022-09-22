# frozen_string_literal: true

module Gitlab
  module Ci
    module Minutes
      # Tracks current remaining minutes in Redis for faster access and tracking
      # consumption of running builds.
      class CachedQuota
        include ::Gitlab::Utils::StrongMemoize

        TTL_REMAINING_MINUTES = 10.minutes

        attr_reader :root_namespace

        def initialize(root_namespace)
          @root_namespace = root_namespace
        end

        def expire!
          ::Gitlab::Redis::SharedState.with do |redis|
            redis.unlink(cache_key)
          end
        end

        # Reduces the remaining minutes by the consumption argument.
        # Then returns the new balance of remaining minutes.
        def track_consumption(consumption)
          new_balance = nil

          ::Gitlab::Redis::SharedState.with do |redis|
            if redis.exists?(cache_key) # rubocop:disable CodeReuse/ActiveRecord
              redis.multi do |multi|
                multi.expire(cache_key, TTL_REMAINING_MINUTES)
                new_balance = multi.incrbyfloat(cache_key, -consumption)
              end
            else
              redis.multi do |multi|
                multi.set(cache_key, uncached_current_balance, nx: true, ex: TTL_REMAINING_MINUTES)
                new_balance = multi.incrbyfloat(cache_key, -consumption)
              end
            end
          end

          new_balance.value.to_f
        end

        # We include the current month in the key so that the entry
        # automatically expires on the 1st of the month, when we reset CI minutes.
        def cache_key
          strong_memoize(:cache_key) do
            now = Time.current.utc
            "ci:minutes:namespaces:#{root_namespace.id}:#{now.year}#{now.month}:remaining"
          end
        end

        private

        def uncached_current_balance
          root_namespace.ci_minutes_usage.current_balance.to_f
        end
      end
    end
  end
end
