# frozen_string_literal: true

module Security
  class ProcessScanResultPolicyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker
    include Gitlab::ExclusiveLeaseHelpers

    LEASE_NAMESPACE = "process_scan_result_policy_worker"
    LEASE_TTL = 5.minutes
    LEASE_RETRY_BASE = 0.1
    LEASE_RETRY_MULTIPLIER = 1.3

    data_consistency :always

    sidekiq_options retry: true

    feature_category :security_policy_management

    def self.lease_key(project, configuration)
      "#{LEASE_NAMESPACE}:#{project.id}:#{configuration.id}"
    end

    def perform(project_id, configuration_id)
      project = Project.find_by_id(project_id)
      configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id)

      return unless project && configuration

      in_lock(self.class.lease_key(project, configuration), ttl: LEASE_TTL, sleep_sec: method(:lease_sleep_sec)) do
        configuration.transaction do
          configuration.delete_scan_finding_rules_for_project(project_id)

          active_scan_result_policies = configuration.active_scan_result_policies

          active_scan_result_policies.each_with_index do |policy, policy_index|
            Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService
              .new(project: project, policy_configuration: configuration, policy: policy, policy_index: policy_index)
              .execute
          end

          Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService
            .new(project: project)
            .execute
        end

        Security::SecurityOrchestrationPolicies::SyncOpenMergeRequestsHeadPipelineService
          .new(project: project)
          .execute
      end
    end

    def lease_sleep_sec(attempts)
      LEASE_RETRY_BASE * (LEASE_RETRY_MULTIPLIER**attempts)
    end
  end
end
