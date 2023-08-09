# frozen_string_literal: true

# This model represents a merge train with many Merge Request 'Cars' for a projects branch
module MergeTrains
  class Train
    def self.all_for_project(project)
      MergeTrains::Car
      .active
      .where(target_project: project)
      .select('DISTINCT ON (target_branch) *')
      .map(&:train)
    end

    attr_reader :project_id, :target_branch

    def initialize(project_id, branch)
      @project_id = project_id
      @target_branch = branch
    end

    def refresh_async
      MergeTrains::RefreshWorker.perform_async(project_id, target_branch)
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

    def all_cars(limit: nil)
      persisted_cars.active.by_id.limit(limit)
    end

    private

    def completed_cars(limit:)
      persisted_cars.complete.by_id(:desc).limit(limit)
    end

    def persisted_cars
      MergeTrains::Car.for_target(project_id, target_branch)
    end
  end
end
