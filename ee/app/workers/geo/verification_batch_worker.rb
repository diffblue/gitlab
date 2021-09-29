# frozen_string_literal: true

module Geo
  class VerificationBatchWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: false
    include GeoQueue
    include LimitedCapacity::Worker
    include ::Gitlab::Geo::LogHelpers

    idempotent!
    loggable_arguments 0

    def perform_work(replicable_name)
      replicator_class = replicator_class_for(replicable_name)

      replicator_class.verify_batch
    end

    # This method helps answer the questions:
    #
    # - Should this worker be reenqueued after it finishes its batch?
    # - How many workers should the parent cron worker start?
    #
    def remaining_work_count(replicable_name)
      replicator_class = replicator_class_for(replicable_name)

      @remaining_work_count ||= replicator_class
        .remaining_verification_batch_count(max_batch_count: max_running_jobs)
    end

    def replicator_class_for(replicable_name)
      @replicator_class ||= ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name)
    end

    def max_running_jobs
      Gitlab::Geo.verification_max_capacity_per_replicator_class
    end
  end
end
