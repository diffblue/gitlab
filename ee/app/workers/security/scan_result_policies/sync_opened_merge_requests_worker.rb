# frozen_string_literal: true

module Security
  module ScanResultPolicies
    class SyncOpenedMergeRequestsWorker
      include ApplicationWorker

      idempotent!
      deduplicate :until_executed, if_deduplicated: :reschedule_once

      data_consistency :always # rubocop:disable SidekiqLoadBalancing/WorkerDataConsistency
      sidekiq_options retry: true
      feature_category :security_policy_management

      def perform(project_id, configuration_id)
        project = Project.find_by_id(project_id)
        configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id)
        return unless project && configuration

        Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService
          .new(project: project, policy_configuration: configuration)
          .execute
      end
    end
  end
end
