# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncFindingsToApprovalRulesService
      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        sync_scan_finding
      end

      private

      attr_reader :pipeline

      def sync_scan_finding
        return if pipeline.security_findings.empty? && !pipeline.complete?

        remove_required_approvals_for_scan_finding
      end

      def merge_requests_for_pipeline
        unless Feature.enabled?(:multi_pipeline_scan_result_policies, pipeline.project)
          return pipeline.merge_requests_as_head_pipeline.opened
        end

        return MergeRequest.none unless pipeline.latest?

        pipeline.all_merge_requests.opened
      end

      def remove_required_approvals_for_scan_finding
        merge_requests_for_pipeline.each do |merge_request|
          UpdateApprovalsService.new(merge_request: merge_request, pipeline: pipeline).execute
        end
      end
    end
  end
end
