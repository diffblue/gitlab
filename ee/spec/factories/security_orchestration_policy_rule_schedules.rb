# frozen_string_literal: true

FactoryBot.define do
  factory :security_orchestration_policy_rule_schedule, class: 'Security::OrchestrationPolicyRuleSchedule' do
    owner { association(:user) }
    security_orchestration_policy_configuration

    policy_index { 0 }
    rule_index { 0 }
    cron { '*/10 * * * *' }
  end
end
