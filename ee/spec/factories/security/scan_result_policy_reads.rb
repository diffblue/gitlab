# frozen_string_literal: true

FactoryBot.define do
  factory :scan_result_policy_read, class: 'Security::ScanResultPolicyRead' do
    security_orchestration_policy_configuration
    project

    orchestration_policy_idx { 0 }
    match_on_inclusion { true }
    sequence :rule_idx
  end
end
