# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::ProcessService do
  let_it_be(:project) { create(:project) }
  let_it_be(:schedule_1) { create(:incident_management_oncall_schedule, :with_rotation, project: project) }
  let_it_be(:schedule_1_users) { schedule_1.participants.map(&:user) }

  let(:escalation_rule) { build(:incident_management_escalation_rule, oncall_schedule: schedule_1 ) }
  let!(:escalation_policy) { create(:incident_management_escalation_policy, project: project, rules: [escalation_rule]) }

  let(:alert) { create(:alert_management_alert, project: project, **alert_params) }
  let(:alert_params) { { status: AlertManagement::Alert::STATUSES[:triggered] } }

  let(:target) { alert }
  let(:process_at) { 5.minutes.ago }
  let(:escalation) { create(:incident_management_pending_alert_escalation, rule: escalation_rule, alert: target, process_at: process_at) }

  let(:service) { described_class.new(escalation) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'it does not escalate' do
      it_behaves_like 'does not send on-call notification'

      it 'does not delete the escalation' do
        subject
        expect { escalation.reload }.not_to raise_error
      end
    end

    shared_examples 'deletes the escalation' do
      specify do
        subject
        expect { escalation.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'all conditions are met' do
      let(:users) { schedule_1_users }

      it_behaves_like 'sends on-call notification'
      it_behaves_like 'deletes the escalation'

      it 'creates a system note' do
        expect(SystemNoteService)
          .to receive(:notify_via_escalation).with(alert, project, [a_kind_of(User)], escalation_policy)
          .and_call_original

        expect { execute }.to change(Note, :count).by(1)
      end
    end

    context 'target is already resolved' do
      let(:target) { create(:alert_management_alert, :resolved, project: project) }

      it_behaves_like 'does not send on-call notification'

      it_behaves_like 'deletes the escalation'
    end

    context 'target status is not above threshold' do
      let(:target) { create(:alert_management_alert, :acknowledged, project: project) }

      it_behaves_like 'it does not escalate'
    end

    context 'escalation is not ready to be processed' do
      let(:process_at) { 5.minutes.from_now }

      it_behaves_like 'it does not escalate'
    end
  end
end
