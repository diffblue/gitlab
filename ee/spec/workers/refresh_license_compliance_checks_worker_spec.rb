# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RefreshLicenseComplianceChecksWorker, feature_category: :security_policy_management do
  subject(:perform) { described_class.new.perform(project_id) }

  let_it_be(:project) { create(:project) }
  let_it_be(:project_id) { project.id }
  let_it_be(:approvals_required) { 15 }

  describe '#perform' do
    before do
      stub_licensed_features(license_scanning: true)
    end

    context "when there are merge requests associated with the project" do
      let_it_be(:open_merge_request) { create(:merge_request, :opened, target_project: project, source_project: project) }
      let_it_be(:closed_merge_request) { create(:merge_request, :closed, target_project: project, source_project: project) }

      let_it_be(:open_pipeline) do
        create(:ee_ci_pipeline, :success, :with_license_scanning_report, :with_cyclonedx_report, project: project,
          merge_requests_as_head_pipeline: [open_merge_request])
      end

      let_it_be(:closed_pipeline) do
        create(:ee_ci_pipeline, :success, :with_license_scanning_report, :with_cyclonedx_report, project: project,
          merge_requests_as_head_pipeline: [closed_merge_request])
      end

      context "when the `#{ApprovalRuleLike::DEFAULT_NAME_FOR_LICENSE_REPORT}` approval rule is enabled" do
        let_it_be_with_reload(:mr_rule_with_scan_result_policy) do
          create(:report_approver_rule, :requires_approval,
            merge_request: open_merge_request,
            approvals_required: approvals_required,
            scan_result_policy_read: create(:scan_result_policy_read)
          )
        end

        let_it_be_with_reload(:open_merge_request_approval_rule) do
          create(:report_approver_rule, :requires_approval, :license_scanning, merge_request: open_merge_request,
            approvals_required: approvals_required)
        end

        let_it_be(:closed_merge_request_approval_rule) do
          create(:report_approver_rule, :license_scanning, merge_request: closed_merge_request,
            approvals_required: 0)
        end

        let_it_be(:project_approval_rule) do
          create(:approval_project_rule, :requires_approval, :license_scanning, project: project,
            approvals_required: approvals_required)
        end

        let!(:denied_policy) { create(:software_license_policy, :denied, project: project, software_license: denied_license) }

        context "when a denied license is present in the license compliance report" do
          let_it_be(:denied_license) { create(:software_license, name: "MIT") }

          before do
            perform
          end

          context 'when the license_scanning_sbom_scanner feature flag is false' do
            before_all do
              stub_feature_flags(license_scanning_sbom_scanner: false)
            end

            specify { expect(open_merge_request_approval_rule.approvals_required).to eql(approvals_required) }
            specify { expect(closed_merge_request_approval_rule.approvals_required).to be_zero }
            specify { expect(mr_rule_with_scan_result_policy.approvals_required).to eql(approvals_required) }
          end

          context 'when the license_scanning_sbom_scanner feature flag is true' do
            before_all do
              create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem", version: "5.1.4", license_name: "MIT")
            end

            specify { expect(open_merge_request_approval_rule.approvals_required).to eql(approvals_required) }
            specify { expect(closed_merge_request_approval_rule.approvals_required).to be_zero }
            specify { expect(mr_rule_with_scan_result_policy.approvals_required).to eql(approvals_required) }
          end
        end

        context "when denied licenses are not present in the most recent license compliance report" do
          let_it_be(:denied_license) { create(:software_license, name: "non-existent-license-name") }

          before do
            perform
          end

          context 'when the license_scanning_sbom_scanner feature flag is false' do
            before_all do
              stub_feature_flags(license_scanning_sbom_scanner: false)
            end

            specify { expect(open_merge_request_approval_rule.approvals_required).to be_zero }
            specify { expect(closed_merge_request_approval_rule.approvals_required).to be_zero }
          end

          context 'when the license_scanning_sbom_scanner feature flag is true' do
            before_all do
              create(:pm_package_version_license, :with_all_relations, name: "activesupport", purl_type: "gem", version: "5.1.4", license_name: "MIT")
            end

            specify { expect(open_merge_request_approval_rule.approvals_required).to be_zero }
            specify { expect(closed_merge_request_approval_rule.approvals_required).to be_zero }
          end
        end
      end
    end

    context "when the project does not exist" do
      let_it_be(:project_id) { "non-existent-project" }

      it { expect { perform }.not_to raise_error }
    end

    context "when the project does not have a license check rule" do
      it { expect { perform }.not_to raise_error }
    end
  end
end
