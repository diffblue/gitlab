# frozen_string_literal: true

module Geo
  class ReverificationBatchWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include GeoQueue
    include LimitedCapacity::Worker
    include ::Gitlab::Geo::LogHelpers

    # Single-file should be fast enough. If increasing this constant over 1, then be sure
    # to add row locking.
    # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/53470/diffs#note_502847744
    MAX_RUNNING_JOBS = 1

    idempotent!
    tags :exclude_from_kubernetes, :exclude_from_gitlab_com
    loggable_arguments 0

    def perform_work(replicable_name)
      replicator_class = replicator_class_for(replicable_name)

      replicator_class.reverify_batch!
    end

    def remaining_work_count(replicable_name)
      replicator_class = replicator_class_for(replicable_name)

      @remaining_work_count ||= replicator_class
        .remaining_reverification_batch_count(max_batch_count: max_running_jobs)
    end

    def max_running_jobs
      MAX_RUNNING_JOBS
    end

    def replicator_class_for(replicable_name)
      @replicator_class ||= ::Gitlab::Geo::Replicator.for_replicable_name(replicable_name)
    end
  end
end
