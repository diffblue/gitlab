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

    stub_licensed_features(dependency_scanning: true, dast: true, license_scanning: true)
  end

  shared_examples 'a successful execution' do
    it "is successful" do
      expect(sync_rules[:status]).to eq(:success)
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

  context "license compliance policy" do
    let(:pipeline) { create(:ci_pipeline, :running, project: project, merge_requests_as_head_pipeline: [merge_request]) }
    let!(:software_license_policy) { create(:software_license_policy, :denied, project: project, software_license: denied_license) }
    let!(:license_compliance_rule) { create(:report_approver_rule, :license_scanning, merge_request: merge_request, approvals_required: 1) }
    let!(:denied_license) { create(:software_license) }

    specify { expect { subject }.not_to change { license_compliance_rule.reload.approvals_required } }
    specify { expect(subject[:status]).to be(:success) }
  end
end
