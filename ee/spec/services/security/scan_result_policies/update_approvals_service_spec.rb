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
    let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project, ref: merge_request.source_branch) }
    let_it_be(:target_pipeline) { create(:ee_ci_pipeline, project: project, ref: merge_request.target_branch) }
    let_it_be(:pipeline_scan) { create(:security_scan, pipeline: pipeline, scan_type: 'dependency_scanning') }
    let_it_be(:pipeline_findings) do
      create_list(:security_finding, 5, scan: pipeline_scan, severity: 'high') do |finding, i|
        finding.update_column(:uuid, uuids[i])
      end
    end

    let(:report_approver_rule) do
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
      target_scan = create(:security_scan, pipeline: target_pipeline, scan_type: 'dependency_scanning')
      create_list(:security_finding, 5, scan: target_scan, severity: 'high') do |finding, i|
        finding.update_column(:uuid, uuids[i])
      end

      create_list(:vulnerabilities_finding, 5, project: project) do |finding, i|
        vulnerability = create(:vulnerability, project: project)
        finding.update_columns(uuid: uuids[i], vulnerability_id: vulnerability.id)
      end
    end

    subject(:service) do
      described_class.new(
        merge_request: merge_request,
        pipeline: pipeline,
        pipeline_findings: pipeline.security_findings
      ).execute
    end

    shared_examples_for 'does not update approvals_required' do
      it do
        expect do
          service
        end.not_to change { report_approver_rule.reload.approvals_required }
      end
    end

    shared_examples_for 'updates approvals_required' do
      it do
        expect do
          service
        end.to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
      end
    end

    context 'when security scan is removed in current pipeline' do
      let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project, ref: merge_request.source_branch) }

      it_behaves_like 'does not update approvals_required'
    end

    context 'when there are no violated approval rules' do
      let(:vulnerabilities_allowed) { 100 }

      it_behaves_like 'updates approvals_required'
    end

    context 'when target pipeline is nil' do
      let_it_be(:merge_request) do
        create(:merge_request, source_branch: 'feature-branch', target_branch: 'target-branch')
      end

      it_behaves_like 'does not update approvals_required'
    end

    context 'when the number of findings in current pipeline exceed the allowed limit' do
      context 'when vulnerability_states has only newly_detected' do
        before do
          report_approver_rule.update!(vulnerability_states: ['newly_detected'])
        end

        it 'does not call VulnerabilitiesCountService' do
          expect(Security::ScanResultPolicies::VulnerabilitiesCountService).not_to receive(:new)

          service
        end
      end

      context 'when vulnerabilities count exceeds the allowed limit' do
        it_behaves_like 'does not update approvals_required'
      end

      context 'when new findings are introduced and it exceeds the allowed limit' do
        let(:vulnerabilities_allowed) { 4 }

        before do
          finding = pipeline_findings.last
          finding.update_column(:uuid, SecureRandom.uuid)
        end

        it_behaves_like 'does not update approvals_required'
      end
    end

    context 'when there are preexisting findings that exceed the allowed limit' do
      context 'when target pipeline is not empty' do
        let_it_be(:pipeline) { create(:ee_ci_pipeline, project: project, ref: merge_request.source_branch) }
        let_it_be(:pipeline_scan) { create(:security_scan, pipeline: pipeline, scan_type: 'dependency_scanning') }

        let(:vulnerability_states) { %w[detected] }

        context 'when vulnerability_states has newly_detected' do
          let(:vulnerability_states) { %w[detected newly_detected] }

          it_behaves_like 'updates approvals_required'
        end

        context 'when vulnerabilities count exceeds the allowed limit' do
          it_behaves_like 'does not update approvals_required'
        end

        context 'when vulnerabilities count does not exceed the allowed limit' do
          let(:vulnerabilities_allowed) { 6 }

          it_behaves_like 'updates approvals_required'
        end
      end

      context 'when target pipeline is nil' do
        let_it_be(:merge_request) do
          create(:merge_request, source_branch: 'feature-branch', target_branch: 'target-branch')
        end

        it_behaves_like 'does not update approvals_required'
      end
    end
  end
end
