# frozen_string_literal: true

module MergeRequests
  class CaptureSuggestedReviewersAcceptedWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :code_review_workflow
    urgency :low
    deduplicate :until_executed

    sidekiq_options retry: 3

    idempotent!

    def perform(merge_request_id, reviewer_ids)
      return if reviewer_ids.blank?

      merge_request = MergeRequest.find_by_id(merge_request_id)
      return unless merge_request&.can_suggest_reviewers?

      response = ::MergeRequests::CaptureSuggestedReviewersAcceptedService
          .new(project: merge_request.project)
          .execute(merge_request, reviewer_ids)

      handle_success(response) if response.success?
    end

    private

    def handle_success(response)
      log_extra_metadata_on_done(:project_id, response.payload[:project_id])
      log_extra_metadata_on_done(:merge_request_id, response.payload[:merge_request_id])
      log_extra_metadata_on_done(:reviewers, response.payload[:reviewers])
    end
  end
end
