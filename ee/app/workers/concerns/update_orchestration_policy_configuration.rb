# frozen_string_literal: true

module UpdateOrchestrationPolicyConfiguration
  def update_policy_configuration(configuration)
    configuration.delete_all_schedules

    unless configuration.policy_configuration_valid?
      configuration.delete_scan_finding_rules

      configuration.update!(configured_at: Time.current)
      return
    end

    configuration.active_scan_execution_policies.each_with_index do |policy, policy_index|
      Security::SecurityOrchestrationPolicies::ProcessRuleService
        .new(policy_configuration: configuration, policy_index: policy_index, policy: policy)
        .execute
    end

    Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService.new(configuration).execute

    configuration.update!(configured_at: Time.current)
  end
end
