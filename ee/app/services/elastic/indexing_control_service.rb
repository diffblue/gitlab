# frozen_string_literal: true

module Elastic
  # Class for managing queues for indexing workers
  # When indexing is paused all jobs are saved in a separate sorted sets in redis
  # This class should only be used with sidekiq workers which extend Elastic::IndexingControl module
  class IndexingControlService
    LIMIT = 1000
    PROJECT_CONTEXT_KEY = "#{Gitlab::ApplicationContext::LOG_KEY}.project"

    def initialize(klass)
      raise ArgumentError, "passed class must extend Elastic::IndexingControl" unless klass.include?(Elastic::IndexingControl)

      @klass = klass
      @queue_name = klass.name.underscore
      @redis_set_key = "elastic:paused_jobs:zset:#{queue_name}"
      @redis_score_key = "elastic:paused_jobs:score:#{queue_name}"
    end

    class << self
      def add_to_waiting_queue!(klass, args, context)
        new(klass).add_to_waiting_queue!(args, context)
      end

      def has_jobs_in_waiting_queue?(klass)
        new(klass).has_jobs_in_waiting_queue?
      end

      def resume_processing!(klass)
        new(klass).resume_processing!
      end

      def queue_size
        Elastic::IndexingControl::WORKERS.sum do |worker_class|
          new(worker_class).queue_size
        end
      end
    end

    def add_to_waiting_queue!(args, context)
      with_redis do |redis|
        redis.zadd(redis_set_key, generate_unique_score(redis), serialize(args, context))
      end
    end

    def queue_size
      with_redis { |redis| redis.zcard(redis_set_key) }
    end

    def has_jobs_in_waiting_queue?
      with_redis { |redis| redis.exists?(redis_set_key) } # rubocop:disable CodeReuse/ActiveRecord
    end

    def resume_processing!
      with_redis do |redis|
        Gitlab::Instrumentation::RedisClusterValidator.allow_cross_slot_commands do
          loop do
            break if Elastic::IndexingControl.non_cached_pause_indexing?

            jobs_with_scores = next_batch_from_waiting_queue(redis)
            break if jobs_with_scores.empty?

            parsed_jobs = jobs_with_scores.map { |j, _| deserialize(j) }

            parsed_jobs.each { |j| send_to_processing_queue(j) }

            remove_jobs_from_waiting_queue(redis, jobs_with_scores)
          end

          redis.del(redis_set_key, redis_score_key) if queue_size == 0
        end
      end
    end

    private

    attr_reader :klass, :queue_name, :redis_set_key, :redis_score_key

    def with_redis(&blk)
      Gitlab::Redis::SharedState.with(&blk) # rubocop:disable CodeReuse/ActiveRecord
    end

    def serialize(args, context)
      {
        args: args,
        # Only include part of the context that would not prevent deduplication
        context: context.slice(PROJECT_CONTEXT_KEY)
      }.to_json
    end

    def deserialize(json)
      Gitlab::Json.parse(json)
    end

    def send_to_processing_queue(job)
      Gitlab::ApplicationContext.with_raw_context(job['context']) do
        klass.perform_async(*job['args'])
      end
    end

    def generate_unique_score(redis)
      redis.incr(redis_score_key)
    end

    def next_batch_from_waiting_queue(redis)
      redis.zrangebyscore(redis_set_key, '-inf', '+inf', limit: [0, LIMIT], with_scores: true)
    end

    def remove_jobs_from_waiting_queue(redis, jobs_with_scores)
      first_score = jobs_with_scores.first.last
      last_score = jobs_with_scores.last.last
      redis.zremrangebyscore(redis_set_key, first_score, last_score)
    end
  end
end
