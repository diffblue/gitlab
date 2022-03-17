# frozen_string_literal: true

FactoryBot.define do
  factory :security_orchestration_policy_configuration, class: 'Security::OrchestrationPolicyConfiguration' do
    project
    namespace { nil }
    security_policy_management_project { association(:project) }

    trait :namespace do
      project { nil }
      namespace
    end
  end
end
