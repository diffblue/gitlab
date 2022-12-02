# frozen_string_literal: true

module Gitlab
  module Counters
    class BufferedCounter
      include Gitlab::ExclusiveLeaseHelpers

      WORKER_DELAY = 10.minutes
      WORKER_LOCK_TTL = 10.minutes

      LUA_FLUSH_INCREMENT_SCRIPT = <<~LUA
        local increment_key, flushed_key = KEYS[1], KEYS[2]
        local increment_value = redis.call("get", increment_key) or 0
        local flushed_value = redis.call("incrby", flushed_key, increment_value)
        if flushed_value == 0 then
          redis.call("del", increment_key, flushed_key)
        else
          redis.call("del", increment_key)
        end
        return flushed_value
      LUA

      def initialize(counter_record, attribute)
        @counter_record = counter_record
        @attribute = attribute
      end

      def get
        redis_state do |redis|
          redis.get(key).to_i
        end
      end

      LUA_INCREMENT_WITH_DEDUPLICATION_SCRIPT = <<~LUA
        local counter_key, refresh_key, refresh_indicator_key = KEYS[1], KEYS[2], KEYS[3]
        local amount, ref = KEYS[4], KEYS[5]
        local tracking_key, opposing_tracking_key = KEYS[6], KEYS[7]

        -- increment to the counter key when not refreshing
        if redis.call("exists", refresh_indicator_key) == 0 then
          return redis.call("incrby", counter_key, amount)
        end

        -- deduplicate and increment to the refresh counter key while refreshing
        local found_duplicate = redis.call("sismember", tracking_key, ref)
        if found_duplicate == 1 then
          return redis.call("get", refresh_key)
        end

        redis.call("sadd", tracking_key, ref)

        local found_opposing_increment = redis.call("sismember", opposing_tracking_key, ref)
        local increment_without_previous_decrement = tonumber(amount) > 0 and found_opposing_increment == 0
        local decrement_with_previous_increment = tonumber(amount) < 0 and found_opposing_increment == 1
        local net_change = 0

        if increment_without_previous_decrement or decrement_with_previous_increment then
          net_change = amount
        end

        return redis.call("incrby", refresh_key, net_change)
      LUA

      def increment(increment)
        result = redis_state do |redis|
          redis.eval(LUA_INCREMENT_WITH_DEDUPLICATION_SCRIPT, keys: increment_args(increment)).to_i
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id, attribute)

        result
      end

      def bulk_increment(increments)
        result = redis_state do |redis|
          redis.pipelined do |pipeline|
            increments.each do |increment|
              pipeline.eval(LUA_INCREMENT_WITH_DEDUPLICATION_SCRIPT, keys: increment_args(increment))
            end
          end
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id, attribute)

        result.last.to_i
      end

      LUA_INITIATE_REFRESH_SCRIPT = <<~LUA
        local counter_key, refresh_indicator_key = KEYS[1], KEYS[2]
        redis.call("del", counter_key)
        redis.call("set", refresh_indicator_key, 1)
      LUA

      def initiate_refresh!
        counter_record.update!(attribute => 0)

        redis_state do |redis|
          redis.eval(LUA_INITIATE_REFRESH_SCRIPT, keys: [key, refresh_indicator_key])
        end
      end

      LUA_FINALIZE_REFRESH_SCRIPT = <<~LUA
        local counter_key, refresh_key, refresh_indicator_key = KEYS[1], KEYS[2], KEYS[3]
        local increment_tracking_key, decrement_tracking_key = KEYS[4], KEYS[5]
        local refresh_amount = redis.call("get", refresh_key) or 0

        redis.call("incrby", counter_key, refresh_amount)
        redis.call("del", refresh_indicator_key, increment_tracking_key, decrement_tracking_key, refresh_key)
      LUA

      def finalize_refresh
        redis_state do |redis|
          keys = [key, refresh_key, refresh_indicator_key, increment_tracking_key, decrement_tracking_key]
          redis.eval(LUA_FINALIZE_REFRESH_SCRIPT, keys: keys)
        end

        FlushCounterIncrementsWorker.perform_in(WORKER_DELAY, counter_record.class.name, counter_record.id, attribute)
      end

      def commit_increment!
        with_exclusive_lease do
          flush_amount = amount_to_be_flushed
          next if flush_amount == 0

          counter_record.transaction do
            counter_record.update_counters_with_lease({ attribute => flush_amount })
            remove_flushed_key
          end

          counter_record.execute_after_commit_callbacks
        end

        counter_record.reset.read_attribute(attribute)
      end

      # amount_to_be_flushed returns the total value to be flushed.
      # The total value is the sum of the following:
      # - current value in the increment_key
      # - any existing value in the flushed_key that has not been flushed
      def amount_to_be_flushed
        redis_state do |redis|
          redis.eval(LUA_FLUSH_INCREMENT_SCRIPT, keys: [key, flushed_key])
        end
      end

      def key
        project_id = counter_record.project.id
        record_name = counter_record.class
        record_id = counter_record.id

        "project:{#{project_id}}:counters:#{record_name}:#{record_id}:#{attribute}"
      end

      def flushed_key
        "#{key}:flushed"
      end

      def refresh_indicator_key
        "#{key}:refresh-in-progress"
      end

      def refresh_key
        "#{key}:refresh"
      end

      def increment_tracking_key
        "#{refresh_key}:+"
      end

      def decrement_tracking_key
        "#{refresh_key}:-"
      end

      private

      attr_reader :counter_record, :attribute

      def increment_args(increment)
        [
          key,
          refresh_key,
          refresh_indicator_key,
          increment.amount,
          increment.ref,
          tracking_key(increment),
          opposing_tracking_key(increment)
        ]
      end

      def tracking_key(increment)
        positive?(increment) ? increment_tracking_key : decrement_tracking_key
      end

      def opposing_tracking_key(increment)
        positive?(increment) ? decrement_tracking_key : increment_tracking_key
      end

      def positive?(increment)
        increment.amount > 0
      end

      def remove_flushed_key
        redis_state do |redis|
          redis.del(flushed_key)
        end
      end

      def redis_state(&block)
        Gitlab::Redis::SharedState.with(&block)
      end

      def with_exclusive_lease(&block)
        lock_key = "#{key}:locked"

        in_lock(lock_key, ttl: WORKER_LOCK_TTL, &block)
      rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
        # a worker is already updating the counters
      end
    end
  end
end
