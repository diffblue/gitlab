# frozen_string_literal: true

module MergeTrains
  class CheckStatusService < BaseService
    def execute(target_project, target_branch, newrev)
      return unless target_project.merge_trains_enabled?

      train = MergeTrains::Train.new(target_project.id, target_branch)

      # If the new revision doesn't exist in the merge train history,
      # that means there was an unexpected commit came from out of merge train cycle.
      unless train.sha_exists_in_history?(newrev)
        car = train.first_car
        car.outdate_pipeline if car
      end
    end
  end
end
