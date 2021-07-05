# frozen_string_literal: true

module Security
  class CreateOrchestrationPolicyWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always
    # rubocop:disable Scalability/CronWorkerContext
    # This worker does not perform work scoped to a context
    include CronjobQueue
    # rubocop:enable Scalability/CronWorkerContext

    feature_category :security_orchestration

    def perform
      Security::OrchestrationPolicyConfiguration.with_outdated_configuration.each_batch do |configurations|
        configurations.each do |configuration|
          unless configuration.policy_configuration_valid?
            configuration.delete_all_schedules
            next
          end

          configuration.active_policies.each_with_index do |policy, policy_index|
            Security::SecurityOrchestrationPolicies::ProcessRuleService
              .new(policy_configuration: configuration, policy_index: policy_index, policy: policy)
              .execute
          end
        end
      end
    end
  end
end
