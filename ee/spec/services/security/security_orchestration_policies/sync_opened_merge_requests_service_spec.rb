# frozen_string_literal: true

require "spec_helper"

RSpec.describe Security::SecurityOrchestrationPolicies::SyncOpenedMergeRequestsService, feature_category: :security_policy_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }
  let_it_be(:group_policy_configuration) do
    create(:security_orchestration_policy_configuration, project: nil, namespace: group)
  end

  let_it_be(:container_scanning_project_approval_rule) do
    create(:approval_project_rule, :scan_finding,
      project: project,
      security_orchestration_policy_configuration: policy_configuration,
      scanners: %w[container_scanning]
    )
  end

  let_it_be(:sast_project_approval_rule) do
    create(:approval_project_rule, :scan_finding,
      project: project,
      security_orchestration_policy_configuration: policy_configuration,
      scanners: %w[sast]
    )
  end

  let_it_be(:project_approval_rule_from_group) do
    create(:approval_project_rule, :scan_finding,
      project: project,
      security_orchestration_policy_configuration: group_policy_configuration,
      scanners: %w[sast]
    )
  end

  let_it_be(:draft_merge_request) do
    create(:merge_request, :draft_merge_request, source_project: project, source_branch: "draft")
  end

  let_it_be(:opened_merge_request) { create(:merge_request, :opened, source_project: project) }
  let_it_be(:merged_merge_request) { create(:merge_request, :merged, source_project: project) }
  let_it_be(:closed_merge_request) { create(:merge_request, :closed, source_project: project) }

  after do
    [ApprovalMergeRequestRule, ApprovalProjectRule, ApprovalMergeRequestRuleSource].each(&:delete_all)
  end

  describe "#execute" do
    subject { described_class.new(project: project, policy_configuration: policy_configuration).execute }

    context 'without head_pipeline for merge request' do
      it 'does not trigger workers' do
        expect(::Ci::SyncReportsToReportApprovalRulesWorker).not_to receive(:perform_async)
        expect(::Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'with head_pipeline' do
      let(:head_pipeline) { create(:ci_pipeline, project: project, ref: opened_merge_request.source_branch) }

      before do
        opened_merge_request.update!(head_pipeline_id: head_pipeline.id)
      end

      context 'with sync_approval_rules_from_findings enabled' do
        it 'triggers both workers' do
          expect(::Ci::SyncReportsToReportApprovalRulesWorker).to receive(:perform_async).with(head_pipeline.id)
          expect(::Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker)
            .to receive(:perform_async).with(head_pipeline.id)

          subject
        end
      end

      context 'with sync_approval_rules_from_findings disabled' do
        before do
          stub_feature_flags(sync_approval_rules_from_findings: false)
        end

        it 'triggers SyncReportsToReportApprovalRulesWorker only' do
          expect(::Ci::SyncReportsToReportApprovalRulesWorker).to receive(:perform_async).with(head_pipeline.id)
          expect(::Security::ScanResultPolicies::SyncFindingsToApprovalRulesWorker)
            .not_to receive(:perform_async).with(head_pipeline.id)

          subject
        end
      end
    end

    it "synchronizes rules to opened merge requests" do
      subject

      [opened_merge_request, draft_merge_request].each do |mr|
        expect(mr.approval_rules.scan_finding.count).to be(2)
      end
    end

    it "does not synchronize rules to merged or closed requests" do
      subject

      [merged_merge_request, closed_merge_request].each do |mr|
        expect(mr.approval_rules.scan_finding.count).to be(0)
      end
    end

    it "does not synchronize rules of another policy configuration" do
      subject

      [opened_merge_request, draft_merge_request].each do |mr|
        expect(mr.approval_rules.map(&:approval_project_rule)).not_to include(project_approval_rule_from_group)
      end
    end

    context "when merge request is synchronized" do
      before do
        opened_merge_request.sync_project_approval_rules_for_policy_configuration(policy_configuration.id)
      end

      it "deletes orphaned join rows" do
        # opened_merge_request already has two rule sources, but
        # draft_merge_request has none, hence the diff of 2
        expect { subject }.to change { ApprovalMergeRequestRuleSource.count }.by(2)
      end

      context "when fully synchronized" do
        it "does not alter rules" do
          expect { subject }.not_to change { opened_merge_request.approval_rules.map(&:attributes) }
        end
      end

      context "when partially synchronized" do
        before do
          opened_merge_request.approval_rules.reload.first.destroy!
        end

        it "creates missing rules" do
          expect { subject }.to change { opened_merge_request.approval_rules.count }.by(1)
        end
      end

      context "when project rule is dirty" do
        let(:states) { %w[detected confirmed] }
        let(:rule) { opened_merge_request.approval_rules.reload.last }

        before do
          sast_project_approval_rule.update_attribute(:vulnerability_states, states)
        end

        it "synchronizes the updated rule" do
          subject

          expect(rule.reload.vulnerability_states).to eq(states)
        end
      end
    end
  end
end
