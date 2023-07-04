# frozen_string_literal: true

# This model represents a merge train with many Merge Request 'Cars' for a projects branch
module MergeTrains
  class Train
    def initialize(project_id, branch)
      @project_id = project_id
      @target_branch = branch
    end

    def all_cars(limit: nil)
      MergeTrains::Car.active.for_target(@project_id, @target_branch).by_id.limit(limit)
    end

    def first_car
      all_cars.first
    end

    def car_count
      all_cars.count
    end

    def sha_exists_in_history?(newrev, limit: 20)
      MergeRequest.where(id: completed_cars(limit: limit).select(:merge_request_id))
        .where('merge_commit_sha = ? OR in_progress_merge_commit_sha = ?', newrev, newrev)
        .exists?
    end

    private

    def completed_cars(limit:)
      MergeTrains::Car.for_target(@project_id, @target_branch)
        .complete.order(id: :desc).limit(limit)
    end
  end
end
