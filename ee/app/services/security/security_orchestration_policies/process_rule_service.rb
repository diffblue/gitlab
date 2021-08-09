# frozen_string_literal: true

module Security
  module SecurityOrchestrationPolicies
    class ProcessRuleService
      def initialize(policy_configuration:, policy_index:, policy:)
        @policy_configuration = policy_configuration
        @policy_index = policy_index
        @policy = policy
      end

      def execute
        policy_configuration.delete_all_schedules
        create_new_schedule_rules
        policy_configuration.update!(configured_at: Time.current)
      end

      private

      attr_reader :policy_configuration, :policy_index, :policy

      def create_new_schedule_rules
        return unless policy_configuration.enabled?

        policy[:rules].each_with_index do |rule, rule_index|
          next if rule[:type] != Security::OrchestrationPolicyConfiguration::RULE_TYPES[:schedule]

          Security::OrchestrationPolicyRuleSchedule
            .create!(
              security_orchestration_policy_configuration: policy_configuration,
              policy_index: policy_index,
              rule_index: rule_index,
              cron: rule[:cadence],
              owner: policy_configuration.policy_last_updated_by
            )
        end
      end
    end
  end
end
