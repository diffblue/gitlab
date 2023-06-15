# frozen_string_literal: true

module SystemNotes
  class MergeTrainService < ::SystemNotes::BaseService
    # Called when 'merge train' is executed
    def enqueue(merge_train)
      index = merge_train.index

      body = if index == 0
               'started a merge train'
             else
               "added this merge request to the merge train at position #{index + 1}"
             end

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'merge train' is canceled
    def cancel
      body = 'removed this merge request from the merge train'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'merge train' is aborted
    def abort(reason)
      ::TodoService.new.merge_train_removed(noteable)

      ##
      # TODO: Abort message should be sent by the system, not a particular user.
      # See https://gitlab.com/gitlab-org/gitlab/issues/29467.
      url = Rails.application.routes.url_helpers.help_page_url(
        'ci/pipelines/merge_trains',
        anchor: 'merge-request-dropped-from-the-merge-train'
      )
      body = "removed this merge request from the merge train because #{reason}. [Learn more](#{url})."

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'add to merge train when pipeline succeeds' is executed
    def add_when_pipeline_succeeds(sha)
      body = "enabled automatic add to merge train when the pipeline for #{sha} succeeds"

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'add to merge train when pipeline succeeds' is canceled
    def cancel_add_when_pipeline_succeeds
      body = 'cancelled automatic add to merge train'

      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end

    # Called when 'add to merge train when pipeline succeeds' is aborted
    def abort_add_when_pipeline_succeeds(reason)
      ::TodoService.new.merge_train_removed(noteable)

      ##
      # TODO: Abort message should be sent by the system, not a particular user.
      # See https://gitlab.com/gitlab-org/gitlab/issues/29467.
      body = "aborted automatic add to merge train because #{reason}"
      create_note(NoteSummary.new(noteable, project, author, body, action: 'merge'))
    end
  end
end
