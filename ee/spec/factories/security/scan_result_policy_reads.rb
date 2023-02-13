# frozen_string_literal: true

FactoryBot.define do
  factory :scan_result_policy_read, class: 'Security::ScanResultPolicyRead' do
    security_orchestration_policy_configuration

    orchestration_policy_idx { 0 }
    match_on_inclusion { true }
  end
end
