# frozen_string_literal: true

FactoryBot.modify do
  factory :incident_management_issuable_escalation_status, class: 'IncidentManagement::IssuableEscalationStatus' do
    trait :paging do
      policy { association :incident_management_escalation_policy, project: issue.project }
      escalations_started_at { Time.current }
    end
  end
end
