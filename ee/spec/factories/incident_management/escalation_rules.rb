# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_escalation_rule, class: 'IncidentManagement::EscalationRule' do
    policy { association :incident_management_escalation_policy, rule_count: 0 }
    oncall_schedule { association :incident_management_oncall_schedule, project: policy.project }
    status { IncidentManagement::EscalationRule.statuses[:acknowledged] }
    elapsed_time_seconds { 5.minutes }
    is_removed { false }

    trait :resolved do
      status { IncidentManagement::EscalationRule.statuses[:resolved] }
    end

    trait :removed do
      is_removed { true }
    end

    trait :with_user do
      oncall_schedule {}
      user { association :user, developer_projects: [policy.project] }
    end
  end
end
