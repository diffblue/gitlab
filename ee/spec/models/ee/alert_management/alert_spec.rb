# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::Alert do
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:environment, refind: true) { create(:environment, project: project) }

  describe 'associations' do
    it { is_expected.to have_many(:pending_escalations).class_name('IncidentManagement::PendingEscalations::Alert') }
  end

  describe 'after_create' do
    it 'attempts to trigger auto rollback' do
      alert = build(:alert_management_alert, :triggered, :critical)

      expect(alert).to receive(:trigger_auto_rollback)

      alert.save!
    end
  end

  describe '#trigger_auto_rollback' do
    subject { alert.trigger_auto_rollback }

    let!(:alert) { create(:alert_management_alert, :triggered, :critical, project: project, environment: environment) }

    before do
      stub_licensed_features(auto_rollback: true)
      environment.project.auto_rollback_enabled = true
    end

    it 'executes AutoRollbackWorker' do
      expect(Deployments::AutoRollbackWorker).to receive(:perform_async).with(environment.id)

      subject
    end

    context 'when status is not triggered' do
      let!(:alert) { create(:alert_management_alert, :acknowledged, :critical, project: project, environment: environment) }

      it 'does not execute AutoRollbackWorker' do
        expect(Deployments::AutoRollbackWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when severity is not critical' do
      let!(:alert) { create(:alert_management_alert, :triggered, :high, project: project, environment: environment) }

      it 'does not execute AutoRollbackWorker' do
        expect(Deployments::AutoRollbackWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when project does not enable auto rollback' do
      before do
        environment.project.auto_rollback_enabled = false
      end

      it 'does not execute AutoRollbackWorker' do
        expect(Deployments::AutoRollbackWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when project does not have a license for auto rollback' do
      before do
        stub_licensed_features(auto_rollback: false)
      end

      it 'does not execute AutoRollbackWorker' do
        expect(Deployments::AutoRollbackWorker).not_to receive(:perform_async)

        subject
      end
    end
  end

  describe '#escalation_policy' do
    let(:alert) { create(:alert_management_alert, project: project) }

    subject { alert.escalation_policy }

    it { is_expected.to eq(nil) }

    context 'when escalation policy exists on the project' do
      it 'returns the projects first (only) escalation policy' do
        policy = create(:incident_management_escalation_policy, project: project)

        expect(subject).to eq(policy)
      end
    end
  end
end
