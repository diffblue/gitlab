# frozen_string_literal: true

module Geo
  # Worker that resynchronizes registries of one data type
  # in batches and marking them as pending
  class BulkMarkPendingBatchWorker
    include ApplicationWorker

    data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency

    include GeoQueue
    include LimitedCapacity::Worker
    include ::Gitlab::Geo::LogHelpers

    # Maximum number of jobs allowed to run concurrently
    MAX_RUNNING_JOBS = 1
    # Reset the Redis cursor to start processing registries
    INITIAL_REDIS_CURSOR = 0

    idempotent!
    loggable_arguments 0

    class << self
      def perform_with_capacity(registry_class)
        restart_redis_cursor(registry_class)

        super(registry_class)
      end

      private

      def restart_redis_cursor(registry_class)
        registry_class.safe_constantize.set_bulk_mark_pending_cursor(INITIAL_REDIS_CURSOR)
      end
    end

    def perform_work(registry_class)
      registry_class = registry_class.safe_constantize

      registry_class.bulk_mark_pending_one_batch!
    end

    # Number of remaining jobs that this worker needs to perform
    #
    # @param registry_class [String] Registry class of the data type being bulk resynced
    # @return [Integer] The number of remaining batches of registry rows that need to be marked pending
    def remaining_work_count(registry_class)
      registry_class = registry_class.safe_constantize

      @remaining_work_count ||= registry_class.remaining_batches_to_bulk_mark_pending(max_batch_count: max_running_jobs)
    end

    def max_running_jobs
      MAX_RUNNING_JOBS
    end
  end
end
