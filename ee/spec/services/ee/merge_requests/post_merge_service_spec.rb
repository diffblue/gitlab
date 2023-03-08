# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::PostMergeService, feature_category: :code_review_workflow do
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

    context 'auditing and tracking invalid logs' do
      shared_examples 'auditing invalid logs' do
        let(:expected_params) do
          {
            name: 'merge_request_invalid_approver_rules',
            author: merge_request.author,
            scope: merge_request.project,
            target: merge_request,
            target_details: {
              title: merge_request.title,
              iid: merge_request.iid,
              id: merge_request.id,
              rule_type: rule.rule_type,
              rule_name: rule.name
            },
            message: 'Invalid merge request approver rules'
          }
        end

        context 'when the rule is valid' do
          let!(:rule) { valid_rule }

          it 'does not audit or track the event' do
            expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
            expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).not_to receive(:track_invalid_approvers)

            subject
          end
        end

        context 'when invalid' do
          let!(:rule) { invalid_rule }

          it 'audits and tracks logs the event' do
            expect(::Gitlab::Audit::Auditor).to receive(:audit).with(expected_params)
            expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).to receive(:track_invalid_approvers).with(merge_request: merge_request)

            subject
          end
        end
      end

      context 'when the rule is code owner' do
        let(:valid_rule) { create(:code_owner_rule, merge_request: merge_request, users: create_list(:user, 1)) }
        let(:invalid_rule) { create(:code_owner_rule, merge_request: merge_request) }

        before do
          stub_licensed_features(code_owner_approval_required: true)
          create(:protected_branch, project: project, name: merge_request.target_branch, code_owner_approval_required: true)
        end

        include_examples 'auditing invalid logs'
      end

      context 'when the rule is any_approver' do
        context 'when the rule is valid' do
          let!(:rule) { create(:any_approver_rule, merge_request: merge_request, users: create_list(:user, 1)) }

          it 'does not audit or track the event' do
            expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
            expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).not_to receive(:track_invalid_approvers)

            subject
          end
        end

        context 'when invalid' do
          let!(:rule) { create(:any_approver_rule, merge_request: merge_request, approvals_required: 1) }

          it 'does not audit or track the event' do
            expect(::Gitlab::Audit::Auditor).not_to receive(:audit)
            expect(Gitlab::UsageDataCounters::MergeRequestActivityUniqueCounter).not_to receive(:track_invalid_approvers)

            subject
          end
        end
      end

      context 'when the rule is approval_merge_request_rule' do
        let(:valid_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: create_list(:user, 1)) }
        let(:invalid_rule) { create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1) }

        include_examples 'auditing invalid logs'
      end

      context 'when the rule is report_approver' do
        let(:valid_rule) { create(:report_approver_rule, merge_request: merge_request, users: create_list(:user, 1)) }
        let(:invalid_rule) { create(:report_approver_rule, merge_request: merge_request, approvals_required: 1) }

        include_examples 'auditing invalid logs'
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

    context 'when merge request is a blocker for other merge requests' do
      let(:blocked_mr_1) { create(:merge_request) }
      let(:blocked_mr_2) { create(:merge_request) }

      before do
        create(:merge_request_block, blocking_merge_request: merge_request, blocked_merge_request: blocked_mr_1)
        create(:merge_request_block, blocking_merge_request: merge_request, blocked_merge_request: blocked_mr_2)
      end

      it 'triggers GraphQL subscription mergeRequestMergeStatusUpdated for each blocked merge request' do
        expect(GraphqlTriggers).not_to receive(:merge_request_merge_status_updated).with(merge_request)
        expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(blocked_mr_1)
        expect(GraphqlTriggers).to receive(:merge_request_merge_status_updated).with(blocked_mr_2)

        subject
      end
    end
  end
end
