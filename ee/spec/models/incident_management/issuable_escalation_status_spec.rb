# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::IssuableEscalationStatus do
  let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status, :paging, :acknowledged) }
  let_it_be(:escalation_policy) { escalation_status.policy }

  subject { escalation_status }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  describe 'validations' do
    context 'when policy and escalation start time are both provided' do
      it { is_expected.to be_valid }
    end

    context 'when neither policy and escalation start time are provided' do
      let(:escalation_status) { build(:incident_management_issuable_escalation_status) }

      it { is_expected.to be_valid }
    end

    context 'when escalation start time is provided without a policy' do
      it 'is invalid' do
        escalation_status.policy_id = nil

        expect(escalation_status).to be_invalid
        expect(escalation_status.errors.messages[:policy]).to eq(['must be set with escalations_started_at'])
      end
    end

    context 'when policy is provided without an escalation start time' do
      it 'is invalid' do
        escalation_status.escalations_started_at = nil

        expect(escalation_status).to be_invalid
        expect(escalation_status.errors.messages[:policy]).to eq(['must be set with escalations_started_at'])
      end
    end
  end

  describe '#trigger' do
    subject(:trigger) { escalation_status.trigger }

    context 'with escalation policy' do
      it 'updates escalations_started_at' do
        expect { trigger }.to change(escalation_status, :escalations_started_at)
        expect(escalation_status.escalations_started_at).to be_present
      end
    end

    context 'without escalation policy' do
      let_it_be(:escalation_status) { create(:incident_management_issuable_escalation_status) }

      it 'does not change escalations_started_at' do
        expect { trigger }.to not_change(escalation_status, :escalations_started_at)
        expect(escalation_status.reload.escalations_started_at).to be_nil
      end
    end
  end

  [:acknowledge, :ignore, :resolve].each do |status_event|
    describe status_event do
      subject { escalation_status.send(status_event) }

      it 'does not change escalations_started_at' do
        expect { subject }.not_to change(escalation_status, :escalations_started_at)
        expect(escalation_status.reload.escalations_started_at).to be_present
      end
    end
  end

  describe '#escalation_policy' do
    let_it_be(:escalation_status, reload: true) { create(:incident_management_issuable_escalation_status) }

    subject { escalation_status.escalation_policy }

    it { is_expected.to eq(nil) }

    context 'when escalation policy exists on the project' do
      it 'returns the projects first (only) escalation policy' do
        policy = create(:incident_management_escalation_policy, project: escalation_status.issue.project)

        expect(subject).to eq(policy)
      end
    end
  end

  describe '#pending_escalation_target' do
    subject { escalation_status.pending_escalation_target }

    it { is_expected.to eq(escalation_status.issue) }
  end
end
