# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncFindingsToApprovalRulesWorker
      include ApplicationWorker

      idempotent!
      data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
      sidekiq_options retry: true

      queue_namespace :security_scans
      feature_category :security_policy_management

      def perform(pipeline_id)
        pipeline = ::Ci::Pipeline.find_by_id(pipeline_id)

        return unless pipeline && Feature.enabled?(:sync_approval_rules_from_findings, pipeline.project)
        return unless pipeline.can_store_security_reports?

        Security::ScanResultPolicies::SyncFindingsToApprovalRulesService.new(pipeline).execute
      end
    end
  end
end
