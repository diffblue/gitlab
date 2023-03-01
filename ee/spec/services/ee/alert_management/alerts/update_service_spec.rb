# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::Alerts::UpdateService, feature_category: :incident_management do
  let_it_be(:user_with_permissions) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:escalation_policy) { create(:incident_management_escalation_policy, project: project) }
  let_it_be(:alert, reload: true) { create(:alert_management_alert, :triggered, project: project) }

  let(:current_user) { user_with_permissions }
  let(:params) { {} }

  let(:service) { described_class.new(alert, current_user, params) }

  before do
    stub_licensed_features(oncall_schedules: true, escalation_policies: true)
  end

  before_all do
    project.add_developer(user_with_permissions)
  end

  describe '#execute' do
    context 'when a status is included' do
      let(:params) { { status: new_status } }

      subject(:execute) { service.execute }

      context 'when moving from a closed status to an open status' do
        let_it_be(:alert, reload: true) { create(:alert_management_alert, :resolved, project: project) }

        let(:new_status) { :triggered }

        it 'creates an escalation' do
          expect(IncidentManagement::PendingEscalations::AlertCreateWorker)
            .to receive(:perform_async)
            .with(a_kind_of(Integer))

          subject
        end
      end

      context 'moving from an open status to closed status' do
        let_it_be(:alert) { create(:alert_management_alert, :triggered, project: project) }
        let_it_be(:escalation) { create(:incident_management_pending_alert_escalation, alert: alert) }

        let(:new_status) { :resolved }
        let(:target) { alert }

        it "deletes the target's escalations" do
          expect { execute }.to change(IncidentManagement::PendingEscalations::Alert, :count).by(-1)
        end
      end

      context 'moving from a status of the same group' do
        let(:new_status) { :ignored }

        it 'does not create or delete escalations' do
          expect { execute }.not_to change(IncidentManagement::PendingEscalations::Alert, :count)
        end
      end
    end
  end
end
