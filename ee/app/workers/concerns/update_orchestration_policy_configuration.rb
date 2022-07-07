# frozen_string_literal: true

module UpdateOrchestrationPolicyConfiguration
  def update_policy_configuration(configuration)
    unless configuration.policy_configuration_valid?
      configuration.delete_all_schedules
      configuration.approval_rules.scan_finding.delete_all if configuration.project?
      configuration.update!(configured_at: Time.current)
      return
    end

    configuration.active_scan_execution_policies.each_with_index do |policy, policy_index|
      Security::SecurityOrchestrationPolicies::ProcessRuleService
        .new(policy_configuration: configuration, policy_index: policy_index, policy: policy)
        .execute
    end

    if configuration.project?
      configuration.transaction do
        configuration.approval_rules.scan_finding.delete_all
        configuration.active_scan_result_policies.each_with_index do |policy, policy_index|
          Security::SecurityOrchestrationPolicies::ProcessScanResultPolicyService
            .new(policy_configuration: configuration, policy: policy, policy_index: policy_index)
            .execute
        end

        Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService
          .new(policy_configuration: configuration)
          .execute
      end
    end

    configuration.update!(configured_at: Time.current)
  end
end
