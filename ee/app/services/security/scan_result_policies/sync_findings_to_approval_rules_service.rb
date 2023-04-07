# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncFindingsToApprovalRulesService
      include Gitlab::Utils::StrongMemoize

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        sync_scan_finding
      end

      private

      attr_reader :pipeline

      def sync_scan_finding
        return if pipeline_findings.empty? && !pipeline.complete?

        remove_required_approvals_for_scan_finding(pipeline.merge_requests_as_head_pipeline.opened)
      end

      def pipeline_findings
        pipeline.security_findings
      end
      strong_memoize_attr :pipeline_findings

      def remove_required_approvals_for_scan_finding(merge_requests)
        merge_requests.each do |merge_request|
          UpdateApprovalsService.new(
            merge_request: merge_request,
            pipeline: pipeline,
            pipeline_findings: pipeline_findings
          ).execute
        end
      end
    end
  end
end
