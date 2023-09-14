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
        project = pipeline&.project

        return unless project&.can_store_security_reports? || project&.approval_rules&.any_merge_request&.exists?

        Security::ScanResultPolicies::SyncFindingsToApprovalRulesService.new(pipeline).execute
      end
    end
  end
end
