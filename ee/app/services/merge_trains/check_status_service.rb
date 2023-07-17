# frozen_string_literal: true

module MergeTrains
  class CheckStatusService < BaseService
    def execute(target_project, target_branch, newrev)
      train = target_project.merge_train_for(target_branch)

      return unless train

      # If the new revision doesn't exist in the merge train history,
      # that means there was an unexpected commit came from out of merge train cycle.
      return if train.sha_exists_in_history?(newrev)

      # If the sha doesn't exist and there is an unexpected commit, outdate_pipeline
      # to create a new merge commit and restart CI
      train.first_car&.outdate_pipeline
    end
  end
end
