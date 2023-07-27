# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::UpdateApprovalsService, feature_category: :security_policy_management do
  describe '#execute' do
    let(:scanners) { %w[dependency_scanning] }
    let(:vulnerabilities_allowed) { 1 }
    let(:severity_levels) { %w[high unknown] }
    let(:vulnerability_states) { %w[detected newly_detected] }

    let_it_be(:uuids) { Array.new(5) { SecureRandom.uuid } }
    let_it_be(:merge_request) { create(:merge_request, source_branch: 'feature-branch', target_branch: 'master') }
    let_it_be(:project) { merge_request.project }
    let_it_be(:pipeline) do
      create(:ee_ci_pipeline, :success, project: project, ref: merge_request.source_branch, sha: 'feature-sha')
    end

    let_it_be(:target_pipeline) do
      create(:ee_ci_pipeline, :success, project: project, ref: merge_request.target_branch, sha: 'target-sha')
    end

    let_it_be(:pipeline_scan) do
      create(:security_scan, :succeeded, project: project, pipeline: pipeline, scan_type: 'dependency_scanning')
    end

    let_it_be(:target_scan) do
      create(:security_scan, :succeeded,
        project: project,
        pipeline: target_pipeline,
        scan_type: 'dependency_scanning'
      )
    end

    let_it_be(:pipeline_findings) do
      create_list(:security_finding, 5, scan: pipeline_scan, severity: 'high') do |finding, i|
        finding.update_column(:uuid, uuids[i])
      end
    end

    let!(:report_approver_rule) do
      create(:report_approver_rule, :scan_finding,
        merge_request: merge_request,
        approvals_required: 2,
        scanners: scanners,
        vulnerabilities_allowed: vulnerabilities_allowed,
        severity_levels: severity_levels,
        vulnerability_states: vulnerability_states
      )
    end

    before do
      create_list(:security_finding, 5, scan: target_scan, severity: 'high') do |finding, i|
        finding.update_column(:uuid, uuids[i])
      end

      create_list(:vulnerabilities_finding, 5, project: project) do |finding, i|
        vulnerability = create(:vulnerability, project: project)
        finding.update_columns(uuid: uuids[i], vulnerability_id: vulnerability.id)
      end
    end

    subject(:execute) do
      described_class.new(merge_request: merge_request, pipeline: pipeline).execute
    end

    shared_examples_for 'does not update approvals_required' do
      it do
        expect do
          execute
        end.not_to change { report_approver_rule.reload.approvals_required }
      end
    end

    shared_examples_for 'sets approvals_required to 0' do
      it do
        expect do
          execute
        end.to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
      end
    end

    shared_examples_for 'new vulnerability_states' do |vulnerability_states|
      before do
        report_approver_rule.update!(vulnerability_states: vulnerability_states)
      end

      it 'does not call VulnerabilitiesCountService' do
        expect(Security::ScanResultPolicies::VulnerabilitiesCountService).not_to receive(:new)

        execute
      end
    end

    context 'when approval rules are empty' do
      let!(:report_approver_rule) { nil }

      it 'does not enqueue Security::GeneratePolicyViolationCommentWorker' do
        expect(Security::GeneratePolicyViolationCommentWorker).not_to receive(:perform_async)

        execute
      end
    end

    context 'when security scan is removed in current pipeline' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, :success, project: project, ref: merge_request.source_branch) }

      context 'when multi_pipeline_scan_result_policies is disabled' do
        before do
          stub_feature_flags(multi_pipeline_scan_result_policies: false)
        end

        it_behaves_like 'does not update approvals_required'
        it_behaves_like 'triggers policy bot comment', :scan_finding, true
      end

      context 'when approval rule scanners is empty' do
        let(:scanners) { [] }

        it_behaves_like 'does not update approvals_required'
        it_behaves_like 'triggers policy bot comment', :scan_finding, true
      end

      context 'when scan type matches the approval rule scanners' do
        it_behaves_like 'does not update approvals_required'
        it_behaves_like 'triggers policy bot comment', :scan_finding, true
      end

      context 'when scan type does not match the approval rule scanners' do
        let(:scanners) { %w[container_scanning] }

        it_behaves_like 'sets approvals_required to 0'
        it_behaves_like 'triggers policy bot comment', :scan_finding, false
      end
    end

    context 'when there are no violated approval rules' do
      let(:vulnerabilities_allowed) { 100 }

      it_behaves_like 'sets approvals_required to 0'

      it_behaves_like 'triggers policy bot comment', :scan_finding, false
    end

    context 'when target pipeline is nil' do
      let_it_be(:merge_request) do
        create(:merge_request, source_branch: 'feature-branch', target_branch: 'target-branch')
      end

      it_behaves_like 'does not update approvals_required'

      it_behaves_like 'triggers policy bot comment', :scan_finding, true
    end

    context 'when the number of findings in current pipeline exceed the allowed limit' do
      context 'when vulnerability_states has only newly_detected' do
        it_behaves_like 'new vulnerability_states', ['newly_detected']
      end

      context 'when vulnerability_states has only new_needs_triage' do
        it_behaves_like 'new vulnerability_states', ['new_needs_triage']
      end

      context 'when vulnerability_states has only new_dismissed' do
        it_behaves_like 'new vulnerability_states', ['new_dismissed']
      end

      context 'when vulnerability_states are new_dismissed and new_needs_triage' do
        it_behaves_like 'new vulnerability_states', %w[new_dismissed new_needs_triage]
      end

      context 'when vulnerabilities count exceeds the allowed limit' do
        it_behaves_like 'does not update approvals_required'

        it_behaves_like 'triggers policy bot comment', :scan_finding, true
      end

      context 'when new findings are introduced and it exceeds the allowed limit' do
        let(:vulnerabilities_allowed) { 4 }
        let(:new_finding_uuid) { SecureRandom.uuid }

        before do
          finding = pipeline_findings.last
          finding.update_column(:uuid, new_finding_uuid)
        end

        it_behaves_like 'does not update approvals_required'

        it_behaves_like 'triggers policy bot comment', :scan_finding, true

        context 'when there are no new dismissed vulnerabilities' do
          let(:vulnerabilities_allowed) { 0 }

          context 'when vulnerability_states is new_dismissed' do
            let(:vulnerability_states) { %w[new_dismissed] }

            it_behaves_like 'new vulnerability_states', ['new_dismissed']

            it_behaves_like 'sets approvals_required to 0'
          end

          context 'when vulnerability_states is new_needs_triage' do
            let(:vulnerability_states) { %w[new_needs_triage] }

            it_behaves_like 'new vulnerability_states', ['new_needs_triage']

            it_behaves_like 'does not update approvals_required'
          end

          context 'when vulnerability_states are new_dismissed and new_needs_triage' do
            let(:vulnerability_states) { %w[new_dismissed new_needs_triage] }

            it_behaves_like 'new vulnerability_states', %w[new_dismissed new_needs_triage]

            it_behaves_like 'does not update approvals_required'
          end
        end

        context 'when there are new dismissed vulnerabilities' do
          let(:vulnerabilities_allowed) { 0 }

          before do
            vulnerability = create(:vulnerability, :dismissed, project: project)
            create(:vulnerabilities_finding, project: project, uuid: new_finding_uuid,
              vulnerability_id: vulnerability.id)
          end

          context 'when vulnerability_states is new_dismissed' do
            let(:vulnerability_states) { %w[new_dismissed] }

            it_behaves_like 'new vulnerability_states', ['new_dismissed']

            it_behaves_like 'does not update approvals_required'
          end

          context 'when vulnerability_states is new_needs_triage' do
            let(:vulnerability_states) { %w[new_needs_triage] }

            it_behaves_like 'new vulnerability_states', ['new_needs_triage']

            it_behaves_like 'sets approvals_required to 0'
          end

          context 'when vulnerability_states are new_dismissed and new_needs_triage' do
            let(:vulnerability_states) { %w[new_dismissed new_needs_triage] }

            it_behaves_like 'new vulnerability_states', %w[new_dismissed new_needs_triage]

            it_behaves_like 'does not update approvals_required'
          end
        end
      end
    end

    context 'when there are preexisting findings that exceed the allowed limit' do
      context 'when target pipeline is not empty' do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, :success, project: project, ref: merge_request.source_branch) }
        let_it_be(:pipeline_scan) do
          create(:security_scan, :succeeded, pipeline: pipeline, scan_type: 'dependency_scanning')
        end

        let(:vulnerability_states) { %w[detected] }

        context 'when vulnerability_states has newly_detected' do
          let(:vulnerability_states) { %w[detected newly_detected] }

          it_behaves_like 'sets approvals_required to 0'

          it_behaves_like 'triggers policy bot comment', :scan_finding, false
        end

        context 'when vulnerability_states has new_needs_triage' do
          let(:vulnerability_states) { %w[detected new_needs_triage] }

          it_behaves_like 'sets approvals_required to 0'

          it_behaves_like 'triggers policy bot comment', :scan_finding, false
        end

        context 'when vulnerability_states has new_dismissed' do
          let(:vulnerability_states) { %w[detected new_dismissed] }

          it_behaves_like 'sets approvals_required to 0'

          it_behaves_like 'triggers policy bot comment', :scan_finding, false
        end

        context 'when vulnerability_states has new_needs_triage and new_dismissed' do
          let(:vulnerability_states) { %w[detected new_needs_triage new_dismissed] }

          it_behaves_like 'sets approvals_required to 0'

          it_behaves_like 'triggers policy bot comment', :scan_finding, false
        end

        context 'when vulnerabilities count exceeds the allowed limit' do
          it_behaves_like 'does not update approvals_required'

          it_behaves_like 'triggers policy bot comment', :scan_finding, true
        end

        context 'when vulnerabilities count does not exceed the allowed limit' do
          let(:vulnerabilities_allowed) { 6 }

          it_behaves_like 'sets approvals_required to 0'

          it_behaves_like 'triggers policy bot comment', :scan_finding, false
        end
      end

      context 'when target pipeline is nil' do
        let_it_be(:merge_request) do
          create(:merge_request, source_branch: 'feature-branch', target_branch: 'target-branch')
        end

        it_behaves_like 'does not update approvals_required'

        it_behaves_like 'triggers policy bot comment', :scan_finding, true
      end
    end

    context 'with multiple pipeline' do
      let_it_be(:related_uuids) { Array.new(5) { SecureRandom.uuid } }
      let_it_be(:related_source_pipeline) do
        create(:ee_ci_pipeline, :success,
          project: project,
          source: :schedule,
          ref: merge_request.source_branch,
          sha: pipeline.sha
        )
      end

      let_it_be(:related_target_pipeline) do
        create(:ee_ci_pipeline, :success,
          project: project,
          source: :schedule,
          ref: merge_request.target_branch,
          sha: target_pipeline.sha
        )
      end

      let_it_be(:related_pipeline_scan) do
        create(:security_scan, :succeeded,
          project: project,
          pipeline: related_source_pipeline,
          scan_type: 'dependency_scanning'
        )
      end

      let_it_be(:related_pipeline_findings) do
        create_list(:security_finding, 5, scan: related_pipeline_scan, severity: 'high') do |finding, i|
          finding.update_column(:uuid, related_uuids[i])
        end
      end

      let_it_be(:related_target_scan) do
        create(:security_scan, :succeeded,
          project: project,
          pipeline: related_target_pipeline,
          scan_type: 'dependency_scanning'
        )
      end

      before do
        create_list(:security_finding, 5, scan: related_target_scan, severity: 'high') do |finding, i|
          finding.update_column(:uuid, related_uuids[i])
        end

        create_list(:vulnerabilities_finding, 5, project: project) do |finding, i|
          vulnerability = create(:vulnerability, project: project)
          finding.update_columns(uuid: related_uuids[i], vulnerability_id: vulnerability.id)
        end
      end

      context 'when security scan is removed in related pipeline' do
        let_it_be(:pipeline) do
          create(:ee_ci_pipeline, :success,
            project: project,
            ref: merge_request.source_branch
          )
        end

        it_behaves_like 'does not update approvals_required'

        it_behaves_like 'triggers policy bot comment', :scan_finding, true
      end
    end

    context 'when the approval rule has vulnerability attributes' do
      let(:report_approver_rule) { nil }
      let_it_be(:policy) { create(:scan_result_policy_read, vulnerability_attributes: { fix_available: true }) }
      let_it_be(:approval_rule) do
        create(:approval_project_rule, :scan_finding, project: project, scan_result_policy_read: policy)
      end

      let_it_be(:mr_rule) do
        create(:approval_merge_request_rule, :scan_finding, merge_request: merge_request,
          approval_project_rule: approval_rule)
      end

      specify do
        expect(Security::ScanResultPolicies::FindingsFinder).to receive(:new).at_least(:once).with(
          anything,
          anything,
          hash_including(fix_available: true, false_positive: nil)
        ).and_call_original

        execute
      end

      context 'when vulnerability_attributes are nil' do
        before do
          policy.update!(vulnerability_attributes: nil)
        end

        specify do
          expect(Security::ScanResultPolicies::FindingsFinder).to receive(:new).at_least(:once).with(
            anything,
            anything,
            hash_including(fix_available: nil, false_positive: nil)
          ).and_call_original

          execute
        end
      end
    end
  end
end
