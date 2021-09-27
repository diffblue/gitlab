# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SyncReportApproverApprovalRules do
  subject(:service) { described_class.new(merge_request) }

  let(:merge_request) { create(:merge_request) }

  describe '#execute' do
    using RSpec::Parameterized::TableSyntax

    before do
      stub_licensed_features(report_approver_rules: true)
    end

    where(:default_name, :report_type) do
      'Vulnerability-Check' | :vulnerability
      'License-Check'       | :license_scanning
      'Coverage-Check'      | :code_coverage
    end

    context 'when a project has a single approval rule for each report_type' do
      with_them do
        let!(:report_approval_project_rule) { create(:approval_project_rule, report_type, project: merge_request.target_project, approvals_required: 2) }
        let!(:regular_approval_project_rule) { create(:approval_project_rule, project: merge_request.target_project) }

        context 'when report_approver_rules are enabled' do
          it 'creates rule for report approvers' do
            expect { service.execute }
              .to change { merge_request.approval_rules.where(name: default_name).count }.from(0).to(1)

            rule = merge_request.approval_rules.find_by(name: default_name)

            expect(rule).to be_report_approver
            expect(rule.report_type).to eq(report_type.to_s)
            expect(rule.name).to eq(report_approval_project_rule.name)
            expect(rule.approvals_required).to eq(report_approval_project_rule.approvals_required)
            expect(rule.approval_project_rule).to eq(report_approval_project_rule)
          end

          it 'updates previous report approval rule if defined' do
            previous_rule = create(:report_approver_rule, report_type, merge_request: merge_request, approvals_required: 0)

            expect { service.execute }
              .not_to change { merge_request.approval_rules.where(name: default_name).count }

            expect(previous_rule.reload).to be_report_approver
            expect(previous_rule.report_type).to eq(report_type.to_s)
            expect(previous_rule.name).to eq(report_approval_project_rule.name)
            expect(previous_rule.approvals_required).to eq(report_approval_project_rule.approvals_required)
            expect(previous_rule.approval_project_rule).to eq(report_approval_project_rule)
          end
        end
      end
    end

    context "when a project has multiple report approval rules" do
      let!(:vulnerability_project_rule) { create(:approval_project_rule, :vulnerability_report, project: merge_request.target_project) }
      let!(:license_compliance_project_rule) { create(:approval_project_rule, :license_scanning, project: merge_request.target_project) }
      let!(:coverage_project_rule) { create(:approval_project_rule, :code_coverage, project: merge_request.target_project) }

      context "when none of the rules have been synchronized to the merge request yet" do
        let(:vulnerability_check_rule) { merge_request.reload.approval_rules.vulnerability_report.last }
        let(:license_check_rule) { merge_request.reload.approval_rules.license_compliance.last }
        let(:coverage_check_rule) { merge_request.reload.approval_rules.coverage.last }

        before do
          vulnerability_project_rule.users << create(:user)
          vulnerability_project_rule.groups << create(:group)
          license_compliance_project_rule.users << create(:user)
          license_compliance_project_rule.groups << create(:group)
          coverage_project_rule.users << create(:user)
          coverage_project_rule.groups << create(:group)

          service.execute
        end

        specify { expect(merge_request.reload.approval_rules.count).to be(3) }
        specify { expect(vulnerability_check_rule).to be_report_approver }
        specify { expect(vulnerability_check_rule.approvals_required).to eql(vulnerability_project_rule.approvals_required) }
        specify { expect(vulnerability_check_rule).to be_vulnerability }
        specify { expect(vulnerability_check_rule.name).to eq(vulnerability_project_rule.name) }
        specify { expect(vulnerability_check_rule.approval_project_rule).to eq(vulnerability_project_rule) }
        specify { expect(license_check_rule).to be_report_approver }
        specify { expect(license_check_rule.approvals_required).to eql(license_compliance_project_rule.approvals_required) }
        specify { expect(license_check_rule).to be_license_scanning }
        specify { expect(license_check_rule.name).to eq(license_compliance_project_rule.name) }
        specify { expect(license_check_rule.approval_project_rule).to eq(license_compliance_project_rule) }
        specify { expect(coverage_check_rule).to be_report_approver }
        specify { expect(coverage_check_rule.approvals_required).to eql(coverage_project_rule.approvals_required) }
        specify { expect(coverage_check_rule).to be_code_coverage }
        specify { expect(coverage_check_rule.name).to eq(coverage_project_rule.name) }
        specify { expect(coverage_check_rule.approval_project_rule).to eq(coverage_project_rule) }
      end

      context "when some of the rules have been synchronized to the merge request" do
        let!(:previous_rule) { create(:report_approver_rule, :license_scanning, merge_request: merge_request) }

        before do
          service.execute
        end

        specify { expect(merge_request.reload.approval_rules.count).to be(3) }
        specify { expect(merge_request.reload.approval_rules.vulnerability_report.count).to be(1) }
        specify { expect(merge_request.reload.approval_rules.coverage.count).to be(1) }
        specify { expect(merge_request.reload.approval_rules.license_compliance).to match_array([previous_rule]) }
      end
    end

    context 'when report_approver_rules are disabled' do
      it 'copies nothing' do
        expect { service.execute }
          .not_to change { merge_request.approval_rules.count }
      end
    end
  end
end
