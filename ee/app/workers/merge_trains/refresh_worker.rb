# frozen_string_literal: true

module MergeTrains
  class RefreshWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3

    queue_namespace :auto_merge
    feature_category :merge_trains
    worker_resource_boundary :cpu

    # Required, since `MergeTrains::RefreshService#execute` is concurrent-unsafe
    deduplicate :until_executed, if_deduplicated: :reschedule_once
    idempotent!

    def perform(target_project_id, target_branch)
      ::MergeTrains::RefreshService
        .new(target_project_id, target_branch)
        .execute
    end
  end
end
