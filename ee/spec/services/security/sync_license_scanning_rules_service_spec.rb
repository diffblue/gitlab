# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::SyncLicenseScanningRulesService, feature_category: :security_policy_management do
  let_it_be(:project) { create(:project, :public, :repository) }
  let(:service) { described_class.new(pipeline) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project) }
  let_it_be(:pipeline) do
    create(:ee_ci_pipeline, :success, :with_cyclonedx_report,
      project: project,
      merge_requests_as_head_pipeline: [merge_request]
    )
  end

  let(:license_report) { ::Gitlab::LicenseScanning.scanner_for_pipeline(project, pipeline).report }
  let!(:ee_ci_build) { create(:ee_ci_build, :success, :license_scanning, pipeline: pipeline, project: project) }

  before_all do
    create(:pm_package_version_license, :with_all_relations,
      name: "nokogiri",
      purl_type: "gem",
      version: "1.8.0",
      license_name: "MIT"
    )
  end

  before do
    stub_licensed_features(license_scanning: true)
  end

  describe '#execute' do
    subject(:execute) { service.execute }

    context 'when license_report is empty' do
      let_it_be(:license_compliance_rule) do
        create(:report_approver_rule, :license_scanning, merge_request: merge_request, approvals_required: 1)
      end

      let_it_be(:pipeline) { create(:ee_ci_pipeline, status: 'pending', project: project) }

      it 'does not update approval rules' do
        expect { execute }.not_to change { license_compliance_rule.reload.approvals_required }
      end

      it 'does not call report' do
        allow_any_instance_of(Gitlab::Ci::Reports::LicenseScanning::Report) do |instance|
          expect(instance).not_to receive(:violates?)
        end

        execute
      end
    end

    context 'with license_finding security policy' do
      let(:license_states) { ['newly_detected'] }
      let(:match_on_inclusion) { true }

      let(:scan_result_policy_read) do
        create(:scan_result_policy_read, license_states: license_states, match_on_inclusion: match_on_inclusion)
      end

      let(:license_finding_rule) do
        create(:report_approver_rule, :license_scanning, merge_request: merge_request, approvals_required: 1,
          scan_result_policy_read: scan_result_policy_read)
      end

      let(:case5) { [['GPL v3', 'A'], ['MIT', 'B'], ['GPL v3', 'C'], ['Apache 2', 'D']] }
      let(:case4) { [['GPL v3', 'A'], ['MIT', 'B'], ['GPL v3', 'C']] }
      let(:case3) { [['GPL v3', 'A'], ['MIT', 'B']] }
      let(:case2) { [['GPL v3', 'A']] }
      let(:case1) { [] }

      context 'when target branch pipeline is empty' do
        it 'does not require approval' do
          expect { execute }.to change { license_finding_rule.reload.approvals_required }.from(1).to(0)
        end
      end

      using RSpec::Parameterized::TableSyntax

      where(:target_branch, :pipeline_branch, :states, :policy_license, :policy_state, :result) do
        ref(:case1) | ref(:case2) | ['newly_detected'] | 'GPL v3' | :denied  | true
        ref(:case2) | ref(:case3) | ['newly_detected'] | 'GPL v3' | :denied  | false
        ref(:case3) | ref(:case4) | ['newly_detected'] | 'GPL v3' | :denied  | true
        ref(:case4) | ref(:case5) | ['newly_detected'] | 'GPL v3' | :denied  | false
        ref(:case1) | ref(:case2) | ['detected'] | 'GPL v3' | :denied  | false
        ref(:case2) | ref(:case3) | ['detected'] | 'GPL v3' | :denied  | true
        ref(:case3) | ref(:case4) | ['detected'] | 'GPL v3' | :denied  | true
        ref(:case4) | ref(:case5) | ['detected'] | 'GPL v3' | :denied  | true

        ref(:case1) | ref(:case2) | ['newly_detected'] | 'MIT' | :allowed  | true
        ref(:case2) | ref(:case3) | ['newly_detected'] | 'MIT' | :allowed  | false
        ref(:case3) | ref(:case4) | ['newly_detected'] | 'MIT' | :allowed  | true
        ref(:case4) | ref(:case5) | ['newly_detected'] | 'MIT' | :allowed  | true
        ref(:case1) | ref(:case2) | ['detected'] | 'MIT' | :allowed  | false
        ref(:case2) | ref(:case3) | ['detected'] | 'MIT' | :allowed  | true
        ref(:case3) | ref(:case4) | ['detected'] | 'MIT' | :allowed  | true
        ref(:case4) | ref(:case5) | ['detected'] | 'MIT' | :allowed  | true
      end

      with_them do
        let(:match_on_inclusion) { policy_state == :denied }
        let(:target_branch_report) { create(:ci_reports_license_scanning_report) }
        let(:pipeline_report) { create(:ci_reports_license_scanning_report) }
        let(:license_states) { states }
        let(:license) { create(:software_license, name: policy_license) }

        before do
          target_branch.each do |ld|
            target_branch_report.add_license(id: nil, name: ld[0]).add_dependency(name: ld[1])
          end

          pipeline_branch.each do |ld|
            pipeline_report.add_license(id: nil, name: ld[0]).add_dependency(name: ld[1])
          end

          create(:software_license_policy, policy_state,
            project: project,
            software_license: license,
            scan_result_policy_read: scan_result_policy_read
          )

          allow(service).to receive(:report).and_return(pipeline_report)
          allow(service).to receive(:target_branch_report).and_return(target_branch_report)
        end

        it 'sync approvals_required' do
          if result
            expect { execute }.not_to change { license_finding_rule.reload.approvals_required }
          else
            expect { execute }.to change { license_finding_rule.reload.approvals_required }.from(1).to(0)
          end
        end
      end
    end
  end
end
