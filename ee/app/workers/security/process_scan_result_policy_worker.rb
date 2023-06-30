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

      sync_policies(project, configuration, active_scan_result_policies)

      if Feature.enabled?(:sync_mr_approval_rules_security_policies, project)
        Security::ScanResultPolicies::SyncOpenedMergeRequestsWorker.perform_async(project_id, configuration_id)
      else
        Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService
        .new(project: project, policy_configuration: configuration)
        .execute
      end
    end

    private

    def sync_policies(project, configuration, active_scan_result_policies)
      configuration.delete_scan_finding_rules_for_project(project.id)
      configuration.delete_software_license_policies(project)

      configuration.delete_scan_result_policy_reads(project) if delete_scan_result_policy_reads?(project)

      active_scan_result_policies.each_with_index do |policy, policy_index|
        Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService
          .new(project: project, policy_configuration: configuration, policy: policy, policy_index: policy_index)
          .execute
      end
    end

    def delete_scan_result_policy_reads?(project)
      Feature.enabled?(:delete_scan_result_policies_by_project_id, project)
    end
  end
end
