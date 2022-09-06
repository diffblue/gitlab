# frozen_string_literal: true

module Gitlab
  module Mirror
    # Runs scheduler every minute
    SCHEDULER_CRON = '* * * * *'
    PULL_CAPACITY_KEY = 'MIRROR_PULL_CAPACITY'
    SCHEDULING_TRACKING_KEY = 'MIRROR_SCHEDULING_TRACKING'
    JITTER = 1.minute

    # TODO: Dynamically determine mirror update interval based on total number
    # of mirrors, average update time, and available concurrency.
    # Issue: https://gitlab.com/gitlab-org/gitlab/issues/5258
    MIN_DELAY = 30.minutes
    # MAX RETRY value was calculated based on the triangular number with a 15 minutes factor
    # https://en.wikipedia.org/wiki/Triangular_number in order to make sure the mirror
    # gets retried for a full day before it becomes hard failed
    MAX_RETRY = 14

    class << self
      def configure_cron_job!
        destroy_cron_job!
        return if Gitlab::Geo.connected? && Gitlab::Geo.secondary?

        Sidekiq::Cron::Job.create(
          name: 'update_all_mirrors_worker',
          cron: SCHEDULER_CRON,
          class: 'UpdateAllMirrorsWorker'
        )
      end

      def max_mirror_capacity_reached?
        available_capacity <= 0
      end

      def reschedule_immediately?
        available_capacity >= capacity_threshold
      end

      def available_capacity
        current_capacity = Gitlab::Redis::SharedState.with { |redis| redis.scard(PULL_CAPACITY_KEY) }.to_i

        available = max_capacity - current_capacity
        if available < 0
          Gitlab::AppLogger.info("Mirror available capacity is below 0: #{available}")
          available = 0
        end

        available
      end

      def increment_capacity(project_id)
        Gitlab::Redis::SharedState.with { |redis| redis.sadd?(PULL_CAPACITY_KEY, project_id) }
      end

      # We do not want negative capacity
      def decrement_capacity(project_id)
        Gitlab::Redis::SharedState.with { |redis| redis.srem?(PULL_CAPACITY_KEY, project_id) }
      end

      def max_delay
        Gitlab::CurrentSettings.mirror_max_delay.minutes + rand(JITTER)
      end

      def min_delay_upper_bound
        MIN_DELAY + JITTER
      end

      def min_delay
        MIN_DELAY + rand(JITTER)
      end

      def max_capacity
        Gitlab::CurrentSettings.mirror_max_capacity
      end

      def capacity_threshold
        Gitlab::CurrentSettings.mirror_capacity_threshold
      end

      def track_scheduling(project_ids)
        Gitlab::Redis::SharedState.with { |redis| redis.sadd(SCHEDULING_TRACKING_KEY, project_ids) }
      end

      def untrack_scheduling(project_id)
        Gitlab::Redis::SharedState.with { |redis| redis.srem?(SCHEDULING_TRACKING_KEY, project_id) }
      end

      def reset_scheduling
        Gitlab::Redis::SharedState.with { |redis| redis.del(SCHEDULING_TRACKING_KEY) }
      end

      def current_scheduling
        Gitlab::Redis::SharedState.with { |redis| redis.scard(SCHEDULING_TRACKING_KEY) }.to_i
      end

      private

      def update_all_mirrors_cron_job
        Sidekiq::Cron::Job.find("update_all_mirrors_worker")
      end

      def destroy_cron_job!
        update_all_mirrors_cron_job&.destroy
      end
    end
  end
end
