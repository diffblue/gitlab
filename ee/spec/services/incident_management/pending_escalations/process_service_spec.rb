# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IncidentManagement::PendingEscalations::ProcessService, feature_category: :incident_management do
  let_it_be(:project) { create(:project) }
  let_it_be(:schedule_1) { create(:incident_management_oncall_schedule, :with_rotation, project: project) }
  let_it_be(:schedule_1_users) { schedule_1.participants.map(&:user) }

  let(:escalation_rule) { build(:incident_management_escalation_rule, oncall_schedule: schedule_1) }
  let!(:escalation_policy) { create(:incident_management_escalation_policy, project: project, rules: [escalation_rule]) }

  let(:process_at) { 5.minutes.ago }

  let(:service) { described_class.new(escalation) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    shared_examples 'does not send on-call notification' do
      specify do
        expect(NotificationService).not_to receive(:new)

        subject
      end
    end

    shared_examples 'does not delete the escalation' do
      specify do
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

    shared_examples 'creates a system note' do
      specify do
        expect(SystemNoteService)
          .to receive(:notify_via_escalation).with(target, project, [a_kind_of(User)], escalation_policy, escalation.type)
          .and_call_original

        expect { execute }.to change(Note, :count).by(1)
      end
    end

    shared_examples 'sends an on-call notification email' do
      let(:notification_async) { double(NotificationService::Async) }

      specify do
        allow(NotificationService).to receive_message_chain(:new, :async).and_return(notification_async)
        expect(notification_async).to receive(notification_action).with(
          users,
          target
        )

        subject
      end
    end

    shared_examples 'escalates correctly when all conditions are met' do
      let(:users) { schedule_1_users }

      it_behaves_like 'sends an on-call notification email'
      it_behaves_like 'deletes the escalation'
      it_behaves_like 'creates a system note'

      context 'when escalation rule is for a user' do
        let(:escalation_rule) { build(:incident_management_escalation_rule, :with_user) }
        let(:users) { [escalation_rule.user] }

        it_behaves_like 'sends an on-call notification email'
        it_behaves_like 'deletes the escalation'
      end
    end

    shared_examples 'does not escalate if escalation should not be processed' do
      context 'when escalation is not scheduled to occur' do
        let(:process_at) { 5.minutes.from_now }

        it_behaves_like 'does not send on-call notification'
        it_behaves_like 'does not delete the escalation'
      end

      context 'when escalation policies feature is unavailable' do
        before do
          stub_licensed_features(oncall_schedules: false, escalation_policies: false)
        end

        it_behaves_like 'does not send on-call notification'
        it_behaves_like 'deletes the escalation'
      end

      context 'target escalation status is resolved' do
        before do
          escalation.escalatable.resolve!
        end

        it_behaves_like 'does not send on-call notification'
        it_behaves_like 'deletes the escalation'
      end

      context 'target status is not above threshold' do
        before do
          escalation.escalatable.acknowledge!
        end

        it_behaves_like 'does not send on-call notification'
        it_behaves_like 'does not delete the escalation'
      end
    end

    context 'alert escalation' do
      let(:alert) { create(:alert_management_alert, project: project, **alert_params) }
      let(:alert_params) { { status: ::IncidentManagement::Escalatable::STATUSES[:triggered] } }
      let(:target) { alert }
      let(:escalation) { create(:incident_management_pending_alert_escalation, rule: escalation_rule, alert: target, process_at: process_at) }
      let(:notification_action) { :notify_oncall_users_of_alert }

      include_examples 'escalates correctly when all conditions are met'
      include_examples 'does not escalate if escalation should not be processed'
    end

    context 'issue escalation' do
      let(:issue) { create(:issue, :incident, project: project) }
      let!(:issue_escalation_status) { create(:incident_management_issuable_escalation_status, issue: target) }
      let(:target) { issue }
      let(:escalation) { create(:incident_management_pending_issue_escalation, rule: escalation_rule, issue: target, process_at: process_at) }
      let(:notification_action) { :notify_oncall_users_of_incident }

      include_examples 'escalates correctly when all conditions are met'
      include_examples 'does not escalate if escalation should not be processed'
    end
  end
end
