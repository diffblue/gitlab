# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncOpenMergeRequestsHeadPipelineService < BaseMergeRequestsService
      extend ::Gitlab::Utils::Override

      def execute
        each_open_merge_request do |merge_request|
          ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(merge_request.head_pipeline_id)
        end
      end

      private

      override :related_merge_requests
      def related_merge_requests
        @project.merge_requests.opened.with_head_pipeline
      end
    end
  end
end
