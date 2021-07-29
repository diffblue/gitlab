# frozen_string_literal: true

FactoryBot.define do
  factory :incident_management_pending_alert_escalation, class: 'IncidentManagement::PendingEscalations::Alert' do
    transient do
      project { association :project }
      policy { association :incident_management_escalation_policy, project: project }
    end

    rule { association :incident_management_escalation_rule, policy: policy }
    alert { association :alert_management_alert, project: rule.policy.project }
    process_at { 5.minutes.from_now }
  end
end
