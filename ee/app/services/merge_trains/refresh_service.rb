# frozen_string_literal: true
module MergeTrains
  # This class is to refresh all merge requests on the merge train that
  # the given merge request belongs to.
  #
  # It performs a sequential update on all merge requests on the train.
  # Multiple runs with the same project and branch should not take place concurrently
  # NOTE: To prevent concurrent refreshes, `MergeTrains::RefreshWorker` implements a locking mechanism through the
  # `deduplicate :until_executed, if_deduplicated: :reschedule_once` option within the worker
  class RefreshService
    DEFAULT_CONCURRENCY = 20
    TRAIN_PROCESSING_LOCK_TIMEOUT = 15.minutes.freeze
    SIGNAL_FOR_REFRESH_REQUEST = 1

    def initialize(target_project_id, target_branch)
      @target_project_id = target_project_id
      @target_branch = target_branch
    end

    def execute
      require_next_recreate = false

      MergeTrains::Car.all_cars(@target_project_id, @target_branch, limit: DEFAULT_CONCURRENCY).each do |car|
        result = MergeTrains::RefreshMergeRequestService
          .new(car.target_project, car.user, require_recreate: require_next_recreate)
          .execute(car.merge_request)

        require_next_recreate = (result[:status] == :error || result[:pipeline_created])
      end
    end
  end
end
