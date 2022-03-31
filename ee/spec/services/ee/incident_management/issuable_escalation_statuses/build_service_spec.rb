# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatuses::BuildService do
  let_it_be(:project) { create(:project) }
  let_it_be(:incident, reload: true) { create(:incident, project: project) }

  let(:service) { described_class.new(incident) }

  subject(:execute) { service.execute }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  it_behaves_like 'initializes new escalation status with expected attributes'

  context 'with associated alert' do
    let_it_be(:alert) { create(:alert_management_alert, :acknowledged, project: project, issue: incident) }

    it_behaves_like 'initializes new escalation status with expected attributes', { status_event: :acknowledge }

    context 'with escalation policy' do
      let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }

      it_behaves_like 'initializes new escalation status with expected attributes' do
        let(:expected_attributes) do
          {
            status_event: :acknowledge,
            policy_id: policy.id,
            escalations_started_at: alert.reload.created_at
          }
        end
      end

      context 'with escalation policies feature unavailable' do
        before do
          stub_licensed_features(oncall_schedules: false, escalation_policies: false)
        end

        it_behaves_like 'initializes new escalation status with expected attributes', { status_event: :acknowledge }
      end
    end
  end
end
