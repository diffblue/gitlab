# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::SyncReportsToApprovalRulesService, '#execute', feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :public, :repository) }

  let(:merge_request) { create(:merge_request, source_project: project) }
  let(:pipeline) { create(:ee_ci_pipeline, :success, project: project, merge_requests_as_head_pipeline: [merge_request]) }
  let(:base_pipeline) { create(:ee_ci_pipeline, :success, project: project, ref: merge_request.target_branch, sha: merge_request.diff_base_sha) }
  let(:scanners) { %w[dependency_scanning] }
  let(:vulnerabilities_allowed) { 0 }
  let(:severity_levels) { %w[high unknown] }
  let(:vulnerability_states) { %w(newly_detected) }

  subject(:sync_rules) { described_class.new(pipeline).execute }

  before do
    allow(Ci::Pipeline).to receive(:find).with(pipeline.id) { pipeline }

    stub_feature_flags(sync_approval_rules_from_findings: false)
    stub_licensed_features(dependency_scanning: true, dast: true, license_scanning: true)
  end

  shared_examples 'a successful execution' do
    it "is successful" do
      expect(sync_rules[:status]).to eq(:success)
    end
  end

  shared_context 'security reports with vulnerabilities' do
    context 'when there are security reports' do
      context 'when pipeline passes' do
        context 'when high-severity vulnerabilities are present' do
          before do
            create(:ee_ci_build, :success, :dependency_scanning, :coverage, name: 'ds_job', pipeline: pipeline, project: project)
          end

          context 'when high-severity vulnerabilities already present in target branch pipeline' do
            before do
              create(:ee_ci_build, :success, :dependency_scanning, :coverage, name: 'ds_job', pipeline: base_pipeline, project: project)
            end

            it 'lowers approvals_required count to zero' do
              expect { subject }
                .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end

          context 'when high-severity vulnerabilities do not present in target branch pipeline' do
            it "won't change approvals_required count" do
              expect { subject }
                .not_to change { report_approver_rule.reload.approvals_required }
            end
          end

          context 'when source approval rule is not present' do
            before do
              approval_project_rule.delete
            end
            it "lowers approvals_required count to zero" do
              expect { subject }
                .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end

          context 'without any scanners related to the security reports' do
            let(:scanners) { %w[sast] }

            it 'lowers approvals_required count to zero' do
              expect { subject }
                .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end

          context 'with the minimum number of vulnerabilities allowed greater than the amount from the security reports' do
            let(:vulnerabilities_allowed) { 10000 }

            it 'lowers approvals_required count to zero' do
              expect { subject }
                .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end

          context 'without any findings related to the severity levels' do
            let(:severity_levels) { %w[info] }

            it 'lowers approvals_required count to zero' do
              expect { subject }
                .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end

          context 'without any vulnerability state related to the security reports' do
            let(:vulnerability_states) { %w(resolved) }

            it 'lowers approvals_required count to zero' do
              expect { subject }
                .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end
        end

        context 'when only low-severity vulnerabilities are present' do
          before do
            create(:ee_ci_build, :success, :low_severity_dast_report, name: 'dast_job', pipeline: pipeline, project: project)
          end

          it 'lowers approvals_required count to zero' do
            expect { subject }
              .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
          end
        end

        context 'when merge_requests are merged' do
          let!(:merge_request) { create(:merge_request, :merged, source_project: project) }

          before do
            create(:ee_ci_build, :success, :dast, name: 'dast_job', pipeline: pipeline, project: project)
          end

          it "won't change approvals_required count" do
            expect { subject }
              .not_to change { report_approver_rule.reload.approvals_required }
          end
        end
      end

      context 'when pipeline fails' do
        before do
          pipeline.update!(status: :failed)
        end

        context 'when high-severity vulnerabilities are present' do
          before do
            create(:ee_ci_build, :success, :dependency_scanning, :coverage, name: 'ds_job', pipeline: pipeline, project: project)
          end

          context 'when high-severity vulnerabilities already present in target branch pipeline' do
            before do
              create(:ee_ci_build, :success, :dependency_scanning, :coverage, name: 'ds_job', pipeline: base_pipeline, project: project)
            end

            it 'lowers approvals_required count to zero' do
              expect { subject }
                .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end

          context 'when high-severity vulnerabilities do not present in target branch pipeline' do
            it "won't change approvals_required count" do
              expect { subject }
                .not_to change { report_approver_rule.reload.approvals_required }
            end
          end
        end

        context 'when only low-severity vulnerabilities are present' do
          before do
            create(:ee_ci_build, :success, :low_severity_dast_report, name: 'dast_job', pipeline: pipeline, project: project)
          end

          it 'lowers approvals_required count to zero' do
            expect { subject }
              .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
          end
        end
      end
    end

    context 'without security reports' do
      let(:pipeline) { create(:ci_pipeline, :running, project: project, merge_requests_as_head_pipeline: [merge_request]) }

      it "won't change approvals_required count" do
        expect { subject }
          .not_to change { report_approver_rule.reload.approvals_required }
      end

      context "license compliance policy" do
        let!(:software_license_policy) { create(:software_license_policy, :denied, project: project, software_license: denied_license) }
        let!(:license_compliance_rule) { create(:report_approver_rule, :license_scanning, merge_request: merge_request, approvals_required: 1) }
        let!(:denied_license) { create(:software_license) }

        specify { expect { subject }.not_to change { license_compliance_rule.reload.approvals_required } }
        specify { expect(subject[:status]).to be(:success) }
      end
    end
  end

  context 'with code coverage rules' do
    let!(:head_pipeline_builds) do
      [
        create(:ci_build, :success, :trace_with_coverage, trace_coverage: 60.0, pipeline: pipeline),
        create(:ci_build, :success, :trace_with_coverage, trace_coverage: 80.0, pipeline: pipeline),
        create(:ci_build, :success, coverage: nil, pipeline: pipeline),
        create(:ci_build, :success, coverage: 40.0, pipeline: pipeline)
      ]
    end

    let!(:report_approver_rule) { create(:report_approver_rule, :code_coverage, merge_request: merge_request, approvals_required: 2) }

    context 'when pipeline is complete' do
      before do
        allow(pipeline).to receive(:complete?).and_return(true)
      end

      context 'and head pipeline coverage is lower than base pipeline coverage' do
        let!(:base_pipeline_builds) do
          [
            create(:ci_build, :success, coverage: 90.0, pipeline: base_pipeline),
            create(:ci_build, :success, coverage: 100.0, pipeline: base_pipeline)
          ]
        end

        it_behaves_like 'a successful execution'

        it "won't lower approvals_required count" do
          expect { sync_rules }
            .not_to change { report_approver_rule.reload.approvals_required }
        end
      end

      context 'and head pipeline coverage is higher than base pipeline coverage' do
        let!(:base_pipeline_builds) do
          [
            create(:ci_build, :success, coverage: 60.0, pipeline: base_pipeline),
            create(:ci_build, :success, coverage: 80.0, pipeline: base_pipeline),
            create(:ci_build, :success, coverage: 30.0, pipeline: base_pipeline)
          ]
        end

        it_behaves_like 'a successful execution'

        it "lowers approvals_required count" do
          expect { sync_rules }
            .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
        end

        context 'when MR is merged' do
          let!(:merge_request) { create(:merge_request, :merged, source_project: project) }

          it_behaves_like 'a successful execution'

          it "won't change approvals_required count" do
            expect { subject }
              .not_to change { report_approver_rule.reload.approvals_required }
          end
        end
      end

      context 'and head pipeline coverage is the same as base pipeline coverage' do
        let!(:base_pipeline_builds) do
          [
            create(:ci_build, :success, coverage: 60.0, pipeline: base_pipeline),
            create(:ci_build, :success, coverage: 80.0, pipeline: base_pipeline),
            create(:ci_build, :success, coverage: 40.0, pipeline: base_pipeline)
          ]
        end

        it_behaves_like 'a successful execution'

        it "lowers approvals_required count" do
          expect { sync_rules }
            .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
        end
      end

      context 'and head pipeline does not have coverage' do
        let!(:head_pipeline_builds) do
          [
            create(:ci_build, :success, coverage: nil, pipeline: pipeline)
          ]
        end

        let!(:base_pipeline_builds) do
          [
            create(:ci_build, :success, coverage: 60.0, pipeline: base_pipeline)
          ]
        end

        it_behaves_like 'a successful execution'

        it "does not lower approvals_required count" do
          expect { sync_rules }
            .not_to change { report_approver_rule.reload.approvals_required }
        end
      end
    end

    context 'when pipeline is incomplete' do
      let!(:base_pipeline_builds) do
        [
          create(:ci_build, :success, coverage: 40.0, pipeline: base_pipeline),
          create(:ci_build, :success, coverage: 30.0, pipeline: base_pipeline)
        ]
      end

      before do
        allow(pipeline).to receive(:complete?).and_return(false)
      end

      it_behaves_like 'a successful execution'

      it "won't lower approvals_required count" do
        expect { sync_rules }
          .not_to change { report_approver_rule.reload.approvals_required }
      end
    end

    context 'when base pipeline is missing' do
      before do
        allow(pipeline).to receive(:complete?).and_return(true)
      end

      it_behaves_like 'a successful execution'

      it "lowers approvals_required count" do
        expect { sync_rules }
          .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
      end
    end

    context 'when base pipeline does not have coverage' do
      before do
        allow(pipeline).to receive(:complete?).and_return(true)
      end

      let!(:base_pipeline_builds) do
        [
          create(:ci_build, :success, coverage: nil, pipeline: base_pipeline)
        ]
      end

      it_behaves_like 'a successful execution'

      it "does not lower approvals_required count" do
        expect { sync_rules }
          .not_to change { report_approver_rule.reload.approvals_required }
      end
    end
  end

  context 'with security orchestration rules' do
    let(:report_approver_rule) { create(:report_approver_rule, :scan_finding, merge_request: merge_request, approvals_required: 2) }
    let(:approval_project_rule) { create(:approval_project_rule, :scan_finding, project: project, approvals_required: 2, scanners: scanners, vulnerabilities_allowed: vulnerabilities_allowed, severity_levels: severity_levels, vulnerability_states: vulnerability_states) }
    let!(:security_orchestration_policy_configuration) { create(:security_orchestration_policy_configuration, project: project) }

    before do
      create(:approval_merge_request_rule_source, approval_merge_request_rule: report_approver_rule, approval_project_rule: approval_project_rule)
    end

    context 'when sync_approval_rules_from_findings is enabled' do
      before do
        stub_feature_flags(sync_approval_rules_from_findings: true)
      end

      it 'does not update approval rules' do
        expect { subject }.not_to change { report_approver_rule.reload.approvals_required }
      end
    end

    context 'when there are security reports' do
      context 'when pipeline passes' do
        context 'when new vulnerabilities are present' do
          before do
            create(:ee_ci_build, :success, :dependency_scanning, name: 'ds_job', pipeline: pipeline, project: project)
          end

          context 'when only existing vulnerabilities are present' do
            before do
              create(:ee_ci_build, :success, :dependency_scanning, name: 'ds_job', pipeline: base_pipeline, project: project)
            end

            it "lowers approval_required count" do
              expect { subject }
              .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end

          context 'with a recent pipeline related to the default branch' do
            before do
              latest_pipeline = create(:ee_ci_pipeline, :success, project: project, ref: merge_request.target_branch)
              create(:ee_ci_build, :success, :dependency_scanning, name: 'ds_job', pipeline: latest_pipeline, project: project)
            end

            it "lowers approval_required count" do
              expect { subject }
              .to change { report_approver_rule.reload.approvals_required }.from(2).to(0)
            end
          end
        end
      end
    end

    include_context 'security reports with vulnerabilities'
  end
end
