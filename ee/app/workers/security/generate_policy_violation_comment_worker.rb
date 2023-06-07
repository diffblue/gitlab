# frozen_string_literal: true

module Security
  class GeneratePolicyViolationCommentWorker
    include ApplicationWorker

    idempotent!
    data_consistency :sticky
    feature_category :security_policy_management

    def perform(merge_request_id, violated_policy)
      merge_request = MergeRequest.find_by_id(merge_request_id)

      unless merge_request
        logger.info(structured_payload(message: 'Merge request not found.', merge_request_id: merge_request_id))
        return
      end

      return if Feature.disabled?(:security_policy_approval_notification, merge_request.project)

      result = Security::ScanResultPolicies::GeneratePolicyViolationCommentService.new(
        merge_request,
        violated_policy
      ).execute

      log_message(result.message.join(', '), merge_request_id, violated_policy) if result.error?
    end

    private

    def log_message(errors, merge_request_id, violated_policy)
      logger.warn(
        structured_payload(
          merge_request_id: merge_request_id,
          violated_policy: violated_policy,
          message: errors
        ))
    end
  end
end
