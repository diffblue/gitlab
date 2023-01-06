# frozen_string_literal: true

module EE
  module MergeRequests
    module AfterCreateService
      extend ::Gitlab::Utils::Override

      override :prepare_merge_request
      def prepare_merge_request(merge_request)
        super

        schedule_sync_for(merge_request.head_pipeline_id)
        schedule_fetch_suggested_reviewers(merge_request)
      end

      private

      def schedule_sync_for(pipeline_id)
        ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(pipeline_id) if pipeline_id
      end

      def schedule_fetch_suggested_reviewers(merge_request)
        return unless merge_request.project.can_suggest_reviewers?
        return unless merge_request.can_suggest_reviewers?

        ::MergeRequests::FetchSuggestedReviewersWorker.perform_async(merge_request.id)
      end
    end
  end
end
