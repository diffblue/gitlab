# frozen_string_literal: true

module Security
  class GeneratePolicyViolationCommentWorker
    include ApplicationWorker

    idempotent!
    data_consistency :sticky
    feature_category :security_policy_management

    def perform(merge_request_id, params = {})
      merge_request = MergeRequest.find_by_id(merge_request_id)

      unless merge_request
        logger.info(structured_payload(message: 'Merge request not found.', merge_request_id: merge_request_id))
        return
      end

      result = Security::ScanResultPolicies::GeneratePolicyViolationCommentService.new(
        merge_request,
        params
      ).execute

      return unless result.error?

      log_message(result.message.join(', '), merge_request_id, params)
    end

    private

    def log_message(errors, merge_request_id, params)
      logger.warn(
        structured_payload(
          merge_request_id: merge_request_id,
          violated_policy: params['violated_policy'],
          report_type: params['report_type'],
          requires_approval: params['requires_approval'],
          message: errors
        ))
    end
  end
end
