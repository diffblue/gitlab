# frozen_string_literal: true

module MergeRequests
  class FetchSuggestedReviewersWorker
    include ApplicationWorker

    data_consistency :always
    feature_category :code_review_workflow
    urgency :low
    deduplicate :until_executed

    sidekiq_options retry: 3

    idempotent!

    # MergeRequests::FetchSuggestedReviewersWorker makes an external RPC request
    worker_has_external_dependencies!

    def perform(merge_request_id)
      merge_request = MergeRequest.find_by_id(merge_request_id)
      return unless merge_request
      return if merge_request.modified_paths.empty?

      result = ::MergeRequests::FetchSuggestedReviewersService
                 .new(project: merge_request.project)
                 .execute(merge_request)

      if result && result[:status] == :success
        merge_request.build_predictions unless merge_request.predictions
        merge_request.predictions.update(suggested_reviewers: result.except(:status))
      else
        logger.error(structured_payload({ result: result }))
      end
    rescue Gitlab::AppliedMl::Errors::ResourceNotAvailable => e
      Gitlab::ErrorTracking.log_exception(
        e,
        project_id: merge_request.project.id,
        merge_request_id: merge_request.id
      )

      nil
    end
  end
end
