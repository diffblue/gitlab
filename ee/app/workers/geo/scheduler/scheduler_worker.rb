# frozen_string_literal: true

module Geo
  module Scheduler
    class SchedulerWorker # rubocop:disable Scalability/IdempotentWorker
      include ApplicationWorker

      data_consistency :always

      sidekiq_options retry: false
      include GeoQueue
      include ExclusiveLeaseGuard
      include ::Gitlab::Geo::LogHelpers
      include ::Gitlab::Utils::StrongMemoize
      include GeoBackoffDelay

      # These workers are enqueued regularly by sidekiq-cron or by an per-shard
      # worker which is enqueued by sidekiq-cron. If one of these workers is
      # already enqueued or running, then there isn't a strong case for
      # enqueuing another. And there are edge cases where enqueuing another
      # would exacerbate a problem. See
      # https://gitlab.com/gitlab-org/gitlab/-/issues/328057.
      deduplicate :until_executed

      DB_RETRIEVE_BATCH_SIZE = 1000
      LEASE_TIMEOUT = 60.minutes
      RUN_TIME = 60.minutes.to_i

      attr_reader :pending_resources, :scheduled_jobs, :start_time, :loops

      def initialize
        @pending_resources = []
        @scheduled_jobs = []
      end

      # The scheduling works as the following:
      #
      # 1. Load a batch of IDs that we need to schedule (DB_RETRIEVE_BATCH_SIZE) into a pending list.
      # 2. Schedule them so that at most `max_capacity` are running at once.
      # 3. When a slot frees, schedule another job.
      # 4. When we have drained the pending list, load another batch into memory, and schedule the
      #    remaining jobs, excluding ones in progress.
      # 5. Quit when we have scheduled all jobs or exceeded MAX_RUNTIME.
      def perform
        @start_time = Time.current.utc
        @loops = 0

        # Prevent multiple Sidekiq workers from attempting to schedule jobs
        try_obtain_lease do
          log_info('Started scheduler')
          reason = :unknown

          begin
            reason = loop do
              break :node_disabled unless node_enabled?
              break :skipped       if should_be_skipped?

              update_jobs_in_progress
              update_pending_resources

              break :over_time if over_time?
              break :complete unless resources_remain?

              # If we're still under the limit after refreshing from the DB, we
              # can end after scheduling the remaining transfers.
              last_batch = reload_queue?
              schedule_jobs
              @loops += 1

              break :last_batch if last_batch
              break :lease_lost unless renew_lease!

              sleep(1)
            end
          rescue StandardError => err
            reason = :error
            log_error(err.message)
            raise err
          ensure
            duration = Time.current.utc - start_time
            log_info('Finished scheduler', total_loops: loops, duration: duration, reason: reason)
          end
        end
      end

      private

      # Subclasses should override this method to provide additional metadata
      # in log messages
      def worker_metadata
        {}
      end

      def base_log_data(message)
        super(message).merge(worker_metadata)
      end

      def db_retrieve_batch_size
        DB_RETRIEVE_BATCH_SIZE
      end

      def lease_timeout
        LEASE_TIMEOUT
      end

      def max_capacity
        raise NotImplementedError
      end

      def run_time
        RUN_TIME
      end

      def reload_queue?
        pending_resources.size < max_capacity
      end

      def resources_remain?
        !pending_resources.empty?
      end

      def over_time?
        (Time.current.utc - start_time) >= run_time
      end

      def should_apply_backoff?
        pending_resources.empty?
      end

      # Takes elements from the front of each array one-by-one, until they are
      # empty. Order is preserved. A limit can be specified, and it defaults to
      # `db_retrieve_batch_size`. The given arrays are mutated.
      #
      # @return [Array] an array composed of elements from the given arrays
      def take_batch(*arrays, batch_size: db_retrieve_batch_size)
        result = []
        total = arrays.sum(&:length)
        iterations = [total, batch_size].min

        iterations.times do
          arrays.size.times do
            if arrays.first.any?
              result << arrays.first.shift
              arrays.rotate! # round-robin
              break
            end

            arrays.shift # remove empty array
          end
        end

        result.compact.uniq
      end

      def update_jobs_in_progress
        status = Gitlab::SidekiqStatus.job_status(scheduled_job_ids)

        # SidekiqStatus returns an array of booleans: true if the job is still running, false otherwise.
        # For each entry, first use `zip` to make { job_id: 123 } -> [ { job_id: 123 }, bool ]
        # Next, filter out the jobs that have completed.
        @scheduled_jobs = @scheduled_jobs.zip(status).map { |(job, running)| job if running }.compact
      end

      def update_pending_resources
        if reload_queue?
          @pending_resources = Gitlab::Geo.uncached_queries { load_pending_resources }
          set_backoff_time! if should_apply_backoff?
        end
      end

      def schedule_jobs
        capacity = max_capacity
        num_to_schedule = [capacity - scheduled_job_ids.size, pending_resources.size].min
        num_to_schedule = 0 if num_to_schedule < 0

        to_schedule = pending_resources.shift(num_to_schedule)
        scheduled = to_schedule.map { |args| schedule_job(*args) }.compact
        scheduled_jobs.concat(scheduled)

        log_info("Loop #{loops}", enqueued: scheduled.length, pending: pending_resources.length, scheduled: scheduled_jobs.length, capacity: capacity)
      end

      def scheduled_job_ids
        scheduled_jobs.map { |data| data[:job_id] }
      end

      def current_node
        Gitlab::Geo.current_node
      end

      def node_enabled?
        # Only check every minute to avoid polling the DB excessively
        unless @last_enabled_check.present? && @last_enabled_check > 1.minute.ago
          @last_enabled_check = Time.current
          clear_memoization(:current_node_enabled)
        end

        strong_memoize(:current_node_enabled) do
          Gitlab::Geo.current_node_enabled?
        end
      end
    end
  end
end
