# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::CreateService, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }

  let(:incident) { create(:incident, project: project) }
  let(:service) { described_class.new(incident) }
  let(:alert_status_name) { :triggered }

  subject(:execute) { service.execute }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  it 'creates an escalation status for the incident with no policy set' do
    expect { execute }.to change { incident.reload.incident_management_issuable_escalation_status }.from(nil)

    status = incident.incident_management_issuable_escalation_status

    expect(status.policy).to eq(nil)
    expect(status.escalations_started_at).to eq(nil)
    expect(status.status_name).to eq(alert_status_name)
  end
end
