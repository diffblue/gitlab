# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::CreateService do
  let_it_be(:project) { create(:project) }

  let(:incident) { create(:incident, project: project) }
  let(:service) { described_class.new(incident) }
  let(:alert_status_name) { :triggered }

  subject(:execute) { service.execute }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
    stub_feature_flags(incident_escalations: true)
  end

  shared_examples 'creates an escalation status for the incident with no policy set' do
    specify do
      expect { execute }.to change { incident.reload.incident_management_issuable_escalation_status }.from(nil)

      status = incident.incident_management_issuable_escalation_status

      expect(status.policy).to eq(nil)
      expect(status.escalations_started_at).to eq(nil)
      expect(status.status_name).to eq(alert_status_name)
    end
  end

  it_behaves_like 'creates an escalation status for the incident with no policy set'

  context 'when incident is associated to an alert' do
    let(:alert) { create(:alert_management_alert, :acknowledged, project: project) }
    let(:incident) { create(:incident, alert_management_alert: alert, project: project) }
    let(:alert_status_name) { alert.status_name }

    context 'when no policy exists' do
      it_behaves_like 'creates an escalation status for the incident with no policy set'
    end

    context 'when policy exists' do
      let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }

      it 'creates an escalation status with the policy info' do
        expect { execute }.to change { incident.reload.incident_management_issuable_escalation_status }

        status = incident.incident_management_issuable_escalation_status

        expect(status.policy).to eq(policy)
        expect(status.escalations_started_at).to be_like_time(alert.created_at)
        expect(status.status_name).to eq(alert.status_name)
      end

      context 'when feature flag is disabled' do
        before do
          stub_feature_flags(incident_escalations: false)
        end

        it_behaves_like 'creates an escalation status for the incident with no policy set'
      end
    end
  end
end
