# frozen_string_literal: true

module Security
  class ProcessScanResultPolicyWorker
    include ApplicationWorker

    idempotent!
    deduplicate :until_executed, if_deduplicated: :reschedule_once

    data_consistency :always
    sidekiq_options retry: true
    feature_category :security_policy_management

    def perform(project_id, configuration_id)
      project = Project.find_by_id(project_id)
      configuration = Security::OrchestrationPolicyConfiguration.find_by_id(configuration_id)
      return unless project && configuration

      active_scan_result_policies = configuration.active_scan_result_policies
      return if active_scan_result_policies.empty?

      configuration.transaction do
        configuration.delete_scan_finding_rules_for_project(project_id)
        configuration.delete_software_license_policies(project)

        active_scan_result_policies.each_with_index do |policy, policy_index|
          Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService
            .new(project: project, policy_configuration: configuration, policy: policy, policy_index: policy_index)
            .execute
        end
      end

      Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService
        .new(project: project, policy_configuration: configuration)
        .execute
    end
  end
end
