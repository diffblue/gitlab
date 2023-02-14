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
    subject { service.execute }

    context 'when license_report is empty' do
      let_it_be(:license_compliance_rule) do
        create(:report_approver_rule, :license_scanning, merge_request: merge_request, approvals_required: 1)
      end

      let_it_be(:pipeline) { create(:ee_ci_pipeline, status: 'pending', project: project) }

      it 'does not update approval rules' do
        expect { subject }.not_to change { license_compliance_rule.reload.approvals_required }
      end
    end

    context "with default license-check rule" do
      let_it_be(:license_compliance_rule) do
        create(:report_approver_rule, :license_scanning, merge_request: merge_request, approvals_required: 1)
      end

      context "when a license violates the license compliance policy" do
        let!(:software_license_policy) do
          create(:software_license_policy, :denied, project: project, software_license: denied_license)
        end

        let(:denied_license) { create(:software_license, name: license_report.license_names[0]) }

        it 'requires approval' do
          expect { subject }.not_to change { license_compliance_rule.reload.approvals_required }
        end
      end

      context "when no licenses violate the license compliance policy" do
        it 'does not require approval' do
          expect { subject }.to change { license_compliance_rule.reload.approvals_required }.from(1).to(0)
        end
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

      context 'when license_scanning_policies is disabled' do
        before do
          stub_feature_flags(license_scanning_policies: false)
        end

        let!(:software_license_policy) do
          create(:software_license_policy, :denied,
            project: project,
            software_license: denied_license,
            scan_result_policy_read: scan_result_policy_read
          )
        end

        let(:denied_license) { create(:software_license, name: license_report.license_names[0]) }

        it 'requires approval' do
          expect { subject }.not_to change { license_finding_rule.reload.approvals_required }
        end
      end

      context 'when license_scanning_policies is enabled' do
        before do
          stub_feature_flags(license_scanning_policies: true)
        end

        context 'when match_on_inclusion is true' do
          context 'when license_scanning contains denied license' do
            let!(:software_license_policy) do
              create(:software_license_policy, :denied,
                project: project,
                software_license: denied_license,
                scan_result_policy_read: scan_result_policy_read
              )
            end

            let(:denied_license) { create(:software_license, name: license_report.license_names[0]) }

            context 'when license_states has only newly_detected' do
              it 'does not require approval' do
                expect { subject }.to change { license_finding_rule.reload.approvals_required }.from(1).to(0)
              end
            end

            context 'when license_states has newly_detected' do
              let(:license_states) { %w[newly_detected detected] }

              it 'requires approval' do
                expect { subject }.not_to change { license_finding_rule.reload.approvals_required }
              end
            end

            context 'when license_states has only detected' do
              let(:license_states) { %w[detected] }

              it 'requires approval' do
                expect { subject }.not_to change { license_finding_rule.reload.approvals_required }
              end
            end
          end

          context 'when license_scanning contains new dependency with un-denied license' do
            let(:default_branch_report) { create(:ci_reports_license_scanning_report) }
            let(:pipeline_report) { create(:ci_reports_license_scanning_report) }

            before do
              default_branch_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library1')
              pipeline_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library1')
              pipeline_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library2')

              allow(service).to receive(:report).and_return(pipeline_report)
              allow(service).to receive(:default_branch_report).and_return(default_branch_report)
            end

            it 'requires approval' do
              expect { subject }.not_to change { license_finding_rule.reload.approvals_required }
            end
          end
        end

        context 'when match_on_inclusion is false' do
          let(:match_on_inclusion) { false }

          context 'when license_states has newly_detected' do
            context 'when license_scanning contains new dependency' do
              let(:default_branch_report) { create(:ci_reports_license_scanning_report) }
              let(:pipeline_report) { create(:ci_reports_license_scanning_report) }

              before do
                default_branch_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library1')
                pipeline_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library1')
                pipeline_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library2')

                allow(service).to receive(:report).and_return(pipeline_report)
                allow(service).to receive(:default_branch_report).and_return(default_branch_report)
              end

              it 'requires approval' do
                expect { subject }.not_to change { license_finding_rule.reload.approvals_required }
              end
            end

            context 'when license_scanning does not contain new dependency' do
              it 'does not require approval' do
                expect { subject }.to change { license_finding_rule.reload.approvals_required }.from(1).to(0)
              end
            end
          end

          context 'when license_states has detected' do
            let(:license_states) { ['detected'] }

            context 'when license_scanning contains un-allowed license' do
              let(:pipeline_report) { create(:ci_reports_license_scanning_report) }

              before do
                pipeline_report.add_license(id: nil, name: 'Denied license').add_dependency(name: 'Library1')

                allow(service).to receive(:report).and_return(pipeline_report)
              end

              it 'requires approval' do
                expect { subject }.not_to change { license_finding_rule.reload.approvals_required }
              end
            end

            context 'when license_scanning contains only allowed license' do
              let(:default_branch_report) { create(:ci_reports_license_scanning_report) }
              let(:pipeline_report) { create(:ci_reports_license_scanning_report) }

              let!(:software_license_policy) do
                create(:software_license_policy, :allowed,
                  project: project,
                  software_license: allowed_license,
                  scan_result_policy_read: scan_result_policy_read
                )
              end

              let(:allowed_license) { create(:software_license, name: 'MIT') }

              before do
                default_branch_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library1')
                pipeline_report.add_license(id: nil, name: 'MIT').add_dependency(name: 'Library1')

                allow(service).to receive(:report).and_return(pipeline_report)
                allow(service).to receive(:default_branch_report).and_return(default_branch_report)
              end

              it 'does not require approval' do
                expect { subject }.to change { license_finding_rule.reload.approvals_required }.from(1).to(0)
              end
            end
          end

          context 'when license_states has both detected and newly_detected' do
            let(:license_states) { %w[newly_detected detected] }

            context 'when default branch already has un-allowed license' do
              let(:default_branch_report) { create(:ci_reports_license_scanning_report) }
              let(:pipeline_report) { create(:ci_reports_license_scanning_report) }

              let!(:software_license_policy) do
                create(:software_license_policy, :allowed,
                  project: project,
                  software_license: allowed_license,
                  scan_result_policy_read: scan_result_policy_read
                )
              end

              let(:allowed_license) { create(:software_license, name: 'MIT') }

              before do
                default_branch_report.add_license(id: nil, name: 'Denied license').add_dependency(name: 'Library1')
                pipeline_report.add_license(id: nil, name: 'Denied license').add_dependency(name: 'Library1')

                allow(service).to receive(:report).and_return(pipeline_report)
                allow(service).to receive(:default_branch_report).and_return(default_branch_report)
              end

              it 'requires approval' do
                expect { subject }.not_to change { license_finding_rule.reload.approvals_required }
              end
            end
          end
        end
      end
    end
  end
end
