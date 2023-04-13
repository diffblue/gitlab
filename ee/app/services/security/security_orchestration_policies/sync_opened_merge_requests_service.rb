# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class SyncOpenedMergeRequestsService < BaseMergeRequestsService
      include Gitlab::Utils::StrongMemoize

      def initialize(project:, policy_configuration:)
        super(project: project)

        @policy_configuration = policy_configuration
      end

      def execute
        each_open_merge_request do |merge_request|
          merge_request.sync_project_approval_rules_for_policy_configuration(@policy_configuration.id)

          head_pipeline = merge_request.actual_head_pipeline
          next unless head_pipeline

          if sync_approval_rules_from_findings_enabled?
            ::Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker.perform_async(head_pipeline.id)
          end

          ::Ci::SyncReportsToReportApprovalRulesWorker.perform_async(head_pipeline.id)
        end
      end

      private

      def sync_approval_rules_from_findings_enabled?
        Feature.enabled?(:sync_approval_rules_from_findings, @project)
      end
      strong_memoize_attr :sync_approval_rules_from_findings_enabled?
    end
  end
end
