# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::EscalationRules::DestroyService, feature_category: :incident_management do
  let!(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:policy) { create(:incident_management_escalation_policy, project: project) }
  let!(:rule_1) { create(:incident_management_escalation_rule, :with_user, user: user, policy: policy) }
  let!(:rule_2) { create(:incident_management_escalation_rule, :with_user, :resolved, user: user, policy: policy) }
  let!(:excluded_rule) { create(:incident_management_escalation_rule, :with_user, user: user, policy: policy, elapsed_time_seconds: 60) }

  let(:other_project) { create(:project) }
  let(:other_policy) { create(:incident_management_escalation_policy, project: other_project) }
  let!(:other_project_rule) { create(:incident_management_escalation_rule, :with_user, user: user, policy: other_policy) }

  let(:escalation_rules) { IncidentManagement::EscalationRule.id_in([rule_1, rule_2, other_project_rule]) }
  let(:notification_service) { NotificationService.new }
  let(:service) { described_class.new(escalation_rules: escalation_rules, user: user) }

  subject(:execute) { service.execute }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  it 'sends an email for each project and deletes the provided escalation rules' do
    allow(NotificationService).to receive(:new).and_return(notification_service)
    expect(notification_service).to receive(:user_escalation_rule_deleted).with(project, user, [rule_1, rule_2]).once
    expect(notification_service).to receive(:user_escalation_rule_deleted).with(other_project, user, [other_project_rule]).once

    execute

    expect { rule_1.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { rule_2.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { other_project_rule.reload }.to raise_error(ActiveRecord::RecordNotFound)
    expect { excluded_rule.reload }.not_to raise_error
  end
end
