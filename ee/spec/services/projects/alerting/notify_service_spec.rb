# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::Alerting::NotifyService do
  let_it_be(:project, refind: true) { create(:project) }

  describe '#execute' do
    let_it_be(:integration) { create(:alert_management_http_integration, project: project) }

    let(:service) { described_class.new(project, payload) }
    let(:token) { integration.token }
    let(:payload) do
      {
        'title' => 'Test alert title'
      }
    end

    subject { service.execute(token, integration) }

    context 'existing alert with same payload fingerprint' do
      let(:existing_alert) { create(:alert_management_alert, :from_payload, project: project, payload: payload) }

      before do
        stub_licensed_features(generic_alert_fingerprinting: fingerprinting_enabled)
        existing_alert # create existing alert after enabling flag
      end

      context 'generic fingerprinting license not enabled' do
        let(:fingerprinting_enabled) { false }

        it 'creates AlertManagement::Alert' do
          expect { subject }.to change(AlertManagement::Alert, :count)
        end

        it 'does not increment the existing alert count' do
          expect { subject }.not_to change { existing_alert.reload.events }
        end
      end

      context 'generic fingerprinting license enabled' do
        let(:fingerprinting_enabled) { true }

        it 'does not create AlertManagement::Alert' do
          expect { subject }.not_to change(AlertManagement::Alert, :count)
        end

        it 'increments the existing alert count' do
          expect { subject }.to change { existing_alert.reload.events }.from(1).to(2)
        end

        context 'end_time provided for subsequent alert' do
          let(:existing_alert) { create(:alert_management_alert, :from_payload, project: project, payload: payload.except('end_time')) }
          let(:payload) { { 'title' => 'title', 'end_time' => Time.current.change(usec: 0).iso8601 } }

          it 'does not create AlertManagement::Alert' do
            expect { subject }.not_to change(AlertManagement::Alert, :count)
          end

          it 'resolves the existing alert', :aggregate_failures do
            expect { subject }.to change { existing_alert.reload.resolved? }.from(false).to(true)
            expect(existing_alert.ended_at).to eq(payload['end_time'])
          end
        end
      end
    end

    context 'with escalation policies feature not enabled' do
      it_behaves_like 'does not create or delete any escalations'
    end

    context 'with escalation policies feature enabled' do
      let_it_be(:policy) { create(:incident_management_escalation_policy, project: project) }
      let_it_be(:payload) { { 'fingerprint' => 'fingerprint' } }

      before do
        stub_licensed_features(oncall_schedules: true, escalation_policies: true, generic_alert_fingerprinting: true)
      end

      include_examples 'creates an escalation'

      context 'existing alert with same payload fingerprint' do
        let_it_be(:alert) { create(:alert_management_alert, :from_payload, project: project, payload: payload) }
        let_it_be(:pending_escalation) { create(:incident_management_pending_alert_escalation, alert: alert) }

        let(:target) { alert }

        it_behaves_like 'does not create or delete any escalations'

        context 'with resolving payload' do
          let_it_be(:payload) do
            {
              'fingerprint' => 'fingerprint',
              'end_time' => Time.current.iso8601
            }
          end

          include_examples "deletes the target's escalations"
        end
      end
    end
  end
end
