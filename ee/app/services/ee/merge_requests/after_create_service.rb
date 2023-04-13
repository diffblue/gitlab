# frozen_string_literal: true

module EE
  module MergeRequests
    module AfterCreateService
      extend ::Gitlab::Utils::Override

      override :prepare_merge_request
      def prepare_merge_request(merge_request)
        super

        schedule_sync_for(merge_request)
        schedule_fetch_suggested_reviewers(merge_request)
      end

      private

      def schedule_sync_for(merge_request)
        pipeline_id = merge_request.head_pipeline_id
        return unless pipeline_id

        ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(pipeline_id)

        return unless ::Feature.enabled?(:sync_approval_rules_from_findings, merge_request.target_project)

        # This is needed here to avoid inconsistent state when the scan result policy is updated after the
        # head pipeline completes and before the merge request is created, we might have inconsistent state.
        ::Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker.perform_async(pipeline_id)
      end

      def schedule_fetch_suggested_reviewers(merge_request)
        return unless merge_request.project.can_suggest_reviewers?
        return unless merge_request.can_suggest_reviewers?

        ::MergeRequests::FetchSuggestedReviewersWorker.perform_async(merge_request.id)
      end
    end
  end
end
