# frozen_string_literal: true

class ClearSharedRunnersMinutesWorker # rubocop:disable Scalability/IdempotentWorker
  include ApplicationWorker

  data_consistency :always

  sidekiq_options retry: 3
  # rubocop:disable Scalability/CronWorkerContext
  # This worker does not perform work scoped to a context
  # all queries are scoped across multiple namespaces
  include CronjobQueue
  # rubocop:enable Scalability/CronWorkerContext
  feature_category :continuous_integration

  LEASE_TIMEOUT = 3600
  TIME_SPREAD = 8.hours.seconds.freeze
  BATCH_SIZE = 100_000

  def perform
    if Feature.enabled?(:ci_parallel_minutes_reset, default_enabled: true)
      start_id = Namespace.minimum(:id)
      last_id = Namespace.maximum(:id)

      batches = [(last_id - start_id) / BATCH_SIZE, 1].max
      execution_offset = (TIME_SPREAD / batches).to_i

      (start_id..last_id).step(BATCH_SIZE).with_index do |batch_start_id, batch_index|
        batch_end_id = batch_start_id + BATCH_SIZE - 1

        delay = execution_offset * batch_index

        # #perform_in is used instead of #perform_async to spread the load
        # evenly accross the first three hours of the month to avoid stressing
        # the database.
        Ci::BatchResetMinutesWorker.perform_in(delay, batch_start_id, batch_end_id)
      end
    else
      return unless try_obtain_lease

      Ci::Minutes::BatchResetService.new.execute!
    end
  end

  private

  def try_obtain_lease
    Gitlab::ExclusiveLease.new('gitlab_clear_shared_runners_minutes_worker',
      timeout: LEASE_TIMEOUT).try_obtain
  end
end
