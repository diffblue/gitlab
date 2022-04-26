# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ExternalStatusChecks::CreateService do
  let_it_be(:project) { create(:project) }
  let_it_be(:protected_branch) { create(:protected_branch, project: project) }

  let(:user) { project.first_owner }
  let(:params) do
    {
      name: 'Test',
      external_url: 'https://external_url.text/hello.json',
      protected_branch_ids: [protected_branch.id]
    }
  end

  subject { described_class.new(container: project, current_user: user, params: params).execute }

  context 'parameters are invalid' do
    let(:params) { { external_url: 'external_url.text/hello.json', name: 'test' } }

    it 'is unsuccessful' do
      expect(subject.success?).to be false
    end

    it 'does not create a new rule' do
      expect { subject }.not_to change { MergeRequests::ExternalStatusCheck.count }
    end
  end

  context 'user not permitted to create approval rule' do
    let_it_be(:user) { create(:user) }

    it 'is unsuccessful' do
      expect(subject.error?).to be true
    end

    it 'does not create a new rule' do
      expect { subject }.not_to change { MergeRequests::ExternalStatusCheck.count }
    end

    it 'responds with the expected errors' do
      expect(subject.message).to eq('Failed to create rule')
      expect(subject.payload[:errors]).to contain_exactly 'Not allowed'
      expect(subject.http_status).to eq(:unauthorized)
    end
  end

  context 'successfully creating approval rule' do
    it 'creates a new ExternalApprovalRule' do
      expect { subject }.to change { MergeRequests::ExternalStatusCheck.count }.by(1)
    end

    it 'is successful' do
      expect(subject.success?).to be true
    end

    it 'includes the newly created rule in its payload' do
      rule = subject.payload[:rule]

      expect(rule).to be_a(MergeRequests::ExternalStatusCheck)
      expect(rule.project).to eq(project)
      expect(rule.external_url).to eq('https://external_url.text/hello.json')
      expect(rule.name).to eq 'Test'
      expect(rule.protected_branches).to contain_exactly(protected_branch)
    end
  end

  describe 'audit events' do
    context 'when licensed' do
      before do
        stub_licensed_features(audit_events: true)
      end

      context 'when external status check save operation succeeds', :request_store do
        it 'logs an audit event' do
          expect { subject }.to change { AuditEvent.count }.by(1)
          expect(AuditEvent.last.details).to include({
                    custom_message: "Added Test status check with protected branch(es) #{protected_branch.name}"
                  })
        end
      end

      context 'when external status check save operation fails' do
        before do
          allow(::MergeRequests::ExternalStatusCheck).to receive(:save).and_return(false)
        end

        it 'does not log any audit event' do
          expect { subject }.not_to change { AuditEvent.count }
        end
      end
    end

    it_behaves_like 'does not create audit event when not licensed'
  end
end
