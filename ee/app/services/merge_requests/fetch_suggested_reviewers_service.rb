# frozen_string_literal: true

module MergeRequests
  class FetchSuggestedReviewersService < BaseProjectService
    def execute(merge_request)
      suggested_reviewers(merge_request)
    end

    private

    def suggested_reviewers(merge_request)
      changes = merge_request.modified_paths
      return error('Merge request contains no modified files') if changes.empty?

      model_input = {
        project_id: merge_request.project_id,
        merge_request_iid: merge_request.iid,
        changes: changes,
        author_username: merge_request.author.username
      }

      result = ::Gitlab::AppliedMl::SuggestedReviewers::Client.new.suggested_reviewers(**model_input)
      success(result)
    end
  end
end
