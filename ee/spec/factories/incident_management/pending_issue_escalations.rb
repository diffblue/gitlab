# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_pending_issue_escalation, class: 'IncidentManagement::PendingEscalations::Issue' do
    transient do
      project { association :project }
      policy { association :incident_management_escalation_policy, project: project }
    end

    rule { association :incident_management_escalation_rule, policy: policy }
    issue { association :incident, project: rule.policy.project }
    process_at { 5.minutes.from_now }
  end
end
