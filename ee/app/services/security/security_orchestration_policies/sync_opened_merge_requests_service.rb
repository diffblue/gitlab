# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncOpenedMergeRequestsService
      def initialize(policy_configuration:)
        @project = policy_configuration.project
      end

      def execute
        opened_merge_requests.each_batch do |mr_batch|
          mr_batch.each do |merge_request|
            MergeRequests::SyncReportApproverApprovalRules
              .new(merge_request)
              .execute(skip_authentication: true)

            pipeline_id = merge_request.head_pipeline_id
            ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(pipeline_id) if pipeline_id
          end
        end
      end

      private

      def opened_merge_requests
        @project.merge_requests.opened
      end
    end
  end
end
