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
        create_new_schedule_rules
      end

      private

      attr_reader :policy_configuration, :policy_index, :policy

      def create_new_schedule_rules
        policy[:rules].each_with_index do |rule, rule_index|
          next if rule[:type] != Security::ScanExecutionPolicy::RULE_TYPES[:schedule]

          rule_schedule = Security::OrchestrationPolicyRuleSchedule.new(
            security_orchestration_policy_configuration: policy_configuration,
            policy_index: policy_index,
            rule_index: rule_index,
            cron: rule[:cadence],
            owner: policy_configuration.policy_last_updated_by)

          next if rule_schedule.exceeds_limits? || !rule_schedule.valid?

          rule_schedule.save!
        end
      end
    end
  end
end
