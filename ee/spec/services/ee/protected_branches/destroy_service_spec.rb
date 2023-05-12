# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedBranches::DestroyService, feature_category: :compliance_management do
  let(:protected_branch) { create(:protected_branch) }
  let(:branch_name) { protected_branch.name }
  let(:project) { protected_branch.project }
  let(:user) { project.first_owner }

  let!(:security_orchestration_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: project)
  end

  describe '#execute' do
    subject(:service) { described_class.new(project, user) }

    it 'adds a security audit event entry' do
      expect { service.execute(protected_branch) }.to change(::AuditEvent, :count).by(1)
    end

    context 'when destroy succeeds but cache refresh fails' do
      let(:bad_cache) { instance_double('ProtectedBranches::CacheService') }
      let(:exception) { RuntimeError }

      before do
        expect(ProtectedBranches::CacheService).to receive(:new).with(project, user, {}).and_return(bad_cache)
        expect(bad_cache).to receive(:refresh).and_raise(exception)
      end

      it "adds a security audit event entry" do
        expect { service.execute(protected_branch) }.to change(::AuditEvent, :count).by(1)
      end

      it "tracks the exception" do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(exception).once

        service.execute(protected_branch)
      end
    end

    context 'when security_orchestration_policies is not licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: false)
        allow(project).to receive(:all_security_orchestration_policy_configurations)
          .and_return([security_orchestration_policy_configuration])
      end

      it 'does not sync scan_finding_approval_rules' do
        expect(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesService).not_to receive(:new)
        expect(Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService).not_to receive(:new)

        service.execute(protected_branch)
      end
    end

    context 'when security_orchestration_policies is licensed' do
      before do
        stub_licensed_features(security_orchestration_policies: true)
        allow(project).to receive(:all_security_orchestration_policy_configurations)
          .and_return([security_orchestration_policy_configuration])
      end

      it 'syncs scan_finding_approval_rules' do
        expect_next_instance_of(
          Security::SecurityOrchestrationPolicies::SyncScanResultPoliciesProjectService,
          security_orchestration_policy_configuration
        ) do |sync_service|
          expect(sync_service).to receive(:execute).with(project.id)
        end

        service.execute(protected_branch)
      end
    end

    context 'when destroy fails' do
      before do
        expect(protected_branch).to receive(:destroy).and_return(false)
      end

      it "doesn't add a security audit event entry" do
        expect { service.execute(protected_branch) }.not_to change(::AuditEvent, :count)
      end
    end
  end
end
