# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PostMergeService do
  let_it_be(:project) { create(:project, :repository) }
  # Works around https://gitlab.com/gitlab-org/gitlab/-/issues/335054
  let_it_be_with_refind(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:current_user) { merge_request.author }
  let(:service) { described_class.new(project: project, current_user: current_user) }

  subject { service.execute(merge_request) }

  describe '#execute' do
    context 'finalize approvals' do
      let(:finalize_service) { double(:finalize_service) }

      it 'executes ApprovalRules::FinalizeService' do
        expect(ApprovalRules::FinalizeService).to receive(:new).and_return(finalize_service)
        expect(finalize_service).to receive(:execute)

        subject
      end
    end

    context 'compliance violations' do
      shared_examples 'does not call the compliance violations worker' do
        it do
          expect(ComplianceManagement::MergeRequests::ComplianceViolationsWorker).not_to receive(:perform_async)

          subject
        end
      end

      context 'when the compliance report feature is unlicensed' do
        before do
          stub_licensed_features(group_level_compliance_dashboard: false)
        end

        it_behaves_like 'does not call the compliance violations worker'
      end

      context 'when the compliance report feature is licensed' do
        before do
          stub_licensed_features(group_level_compliance_dashboard: true)
        end

        it 'calls the compliance violations worker asynchronously' do
          expect(ComplianceManagement::MergeRequests::ComplianceViolationsWorker).to receive(:perform_async).with(merge_request.id)

          subject
        end
      end
    end

    context 'security orchestration policy configuration' do
      let(:security_orchestration_enabled) { true }
      let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: main_project, security_policy_management_project: project) }

      let_it_be(:main_project) { create(:project, :repository) }
      let_it_be(:another_project) { create(:project, :repository) }
      let_it_be(:another_policy_configuration) { create(:security_orchestration_policy_configuration, project: another_project, security_policy_management_project: project) }

      before do
        stub_licensed_features(security_orchestration_policies: security_orchestration_enabled)
      end

      it 'executes Security::SyncScanResultPolicyWorker for each configuration project' do
        expect(Security::SyncScanPoliciesWorker).to receive(:perform_async).with(policy_configuration.id)
        expect(Security::SyncScanPoliciesWorker).to receive(:perform_async).with(another_policy_configuration.id)

        subject
      end

      context 'without licensed feature' do
        let(:security_orchestration_enabled) { false }

        it 'does not execute Security::SyncScanResultPolicyWorker for each configuration project' do
          expect(Security::SyncScanPoliciesWorker).not_to receive(:perform_async)

          subject
        end
      end

      context 'with unrelated policy configurations' do
        let(:policy_configuration) { create(:security_orchestration_policy_configuration, project: main_project, security_policy_management_project: unrelated_project) }

        let_it_be(:unrelated_project) { create(:project, :repository) }

        it 'does not execute Security::SyncScanResultPolicyWorker for each configuration project' do
          expect(Security::SyncScanPoliciesWorker).not_to receive(:perform_async).with(policy_configuration.id)

          subject
        end
      end
    end
  end
end
