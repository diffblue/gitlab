# frozen_string_literal: true

module EE
  module MergeRequests
    module AfterCreateService
      extend ::Gitlab::Utils::Override

      override :prepare_merge_request
      def prepare_merge_request(merge_request)
        super

        if current_user.project_bot?
          log_audit_event(merge_request, 'merge_request_created_by_project_bot',
            "Created merge request #{merge_request.title}")
        end

        schedule_sync_for(merge_request)
        schedule_fetch_suggested_reviewers(merge_request)
        track_usage_event if merge_request.project.scan_result_policy_reads.any?
      end

      private

      def schedule_sync_for(merge_request)
        pipeline_id = merge_request.head_pipeline_id
        return unless pipeline_id

        ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(pipeline_id)

        # This is needed here to avoid inconsistent state when the scan result policy is updated after the
        # head pipeline completes and before the merge request is created, we might have inconsistent state.
        ::Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker.perform_async(pipeline_id)
      end

      def schedule_fetch_suggested_reviewers(merge_request)
        return unless merge_request.project.can_suggest_reviewers?
        return unless merge_request.can_suggest_reviewers?

        ::MergeRequests::FetchSuggestedReviewersWorker.perform_async(merge_request.id)
      end

      def track_usage_event
        ::Gitlab::UsageDataCounters::HLLRedisCounter.track_event(
          'users_creating_merge_requests_with_security_policies',
          values: current_user.id
        )
      end
    end
  end
end
