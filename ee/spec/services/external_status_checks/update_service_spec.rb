# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalStatusChecks::UpdateService, feature_category: :projects do
  let_it_be(:project) { create(:project) }
  let_it_be(:check) { create(:external_status_check, project: project) }
  let_it_be(:protected_branch) { create(:protected_branch, project: project) }

  let(:current_user) { project.first_owner }
  let(:params) { { id: project.id, check_id: check.id, external_url: 'http://newvalue.com', name: 'new name', protected_branch_ids: [protected_branch.id] } }

  subject { described_class.new(container: project, current_user: current_user, params: params).execute }

  context 'when current user is project owner' do
    it 'updates an approval rule' do
      subject

      check.reload

      expect(check.external_url).to eq('http://newvalue.com')
      expect(check.name).to eq('new name')
      expect(check.protected_branches).to contain_exactly(protected_branch)
    end

    it 'is successful' do
      expect(subject.success?).to be true
    end
  end

  context 'when current user is not a project owner' do
    let_it_be(:current_user) { create(:user) }

    it 'does not change an approval rule' do
      expect { subject }.not_to change { check.name }
    end

    it 'is unsuccessful' do
      expect(subject.error?).to be true
    end

    it 'returns an unauthorized status' do
      expect(subject.http_status).to eq(:unauthorized)
    end

    it 'contains an appropriate message and error' do
      expect(subject.message).to eq('Failed to update rule')
      expect(subject.payload[:errors]).to contain_exactly('Not allowed')
    end
  end

  describe 'audit events' do
    context 'when licensed' do
      before do
        stub_licensed_features(audit_events: true)
      end
      let_it_be(:master_branch) { create(:protected_branch, project: project, name: 'master') }
      let_it_be(:main_branch) { create(:protected_branch, project: project, name: 'main') }
      let_it_be(:external_status_check, reload: true) { create(:external_status_check, name: 'QA', project: project, protected_branches: []) }

      context 'when a branch is added', :request_store do
        context 'when a new branch is added' do
          let_it_be(:params) { { id: project.id, check_id: external_status_check.id, protected_branch_ids: [main_branch.id] } }

          it 'logs an audit event' do
            expect { subject }.to change { AuditEvent.count }.by(1)
            expect(AuditEvent.last.details[:custom_message]).to eq "Added protected branch main to QA status check and removed all other branches from status check"
          end
        end

        context 'when another branch is added' do
          before do
            external_status_check.update!(protected_branches: [main_branch])
          end

          let_it_be(:params) { { id: project.id, check_id: external_status_check.id, protected_branch_ids: [main_branch.id, master_branch.id] } }

          it 'logs an audit event' do
            expect { subject }.to change { AuditEvent.count }.by(1)
            expect(AuditEvent.last.details[:custom_message]).to eq "Added protected branch master to QA status check"
          end
        end
      end

      context 'when a branch is removed', :request_store do
        context 'when the only branch is removed' do
          before do
            external_status_check.update!(protected_branches: [main_branch])
          end

          let_it_be(:params) { { id: project.id, check_id: external_status_check.id, protected_branch_ids: [] } }

          it 'logs an audit event' do
            expect { subject }.to change { AuditEvent.count }.by(1)
            expect(AuditEvent.last.details[:custom_message]).to eq "Added all branches to QA status check"
          end
        end

        context 'when a branch is removed' do
          before do
            external_status_check.update!(protected_branches: [main_branch, master_branch])
          end

          let_it_be(:params) { { id: project.id, check_id: external_status_check.id, protected_branch_ids: [main_branch.id] } }

          it 'logs an audit event' do
            expect { subject }.to change { AuditEvent.count }.by(1)
            expect(AuditEvent.last.details[:custom_message]).to eq "Removed protected branch master from QA status check"
          end
        end
      end
    end

    it 'executes ExternalStatusCheckChangesAuditor' do
      expect(Audit::ExternalStatusCheckChangesAuditor).to receive(:new).with(current_user, check).and_call_original

      subject
    end
  end

  it_behaves_like 'does not create audit event when not licensed'
end
