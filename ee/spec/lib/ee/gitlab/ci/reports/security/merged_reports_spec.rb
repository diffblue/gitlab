# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::MergedReports, feature_category: :security_policy_management do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:artifact) { create(:ci_job_artifact, :sast) }

  let(:security_reports) { Gitlab::Ci::Reports::Security::Reports.new(pipeline) }
  let(:merged_reports) { described_class.new(pipeline, [security_reports]) }

  describe "#violates_default_policy_against?" do
    let(:high_severity_dast) { build(:ci_reports_security_finding, severity: 'high', report_type: :dast) }
    let(:vulnerabilities_allowed) { 0 }
    let(:severity_levels) { %w[critical high] }
    let(:vulnerability_states) { %w[newly_detected] }
    let(:report_types) { [] }

    subject do
      merged_reports.violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels,
     vulnerability_states, report_types)
    end

    before do
      security_reports.get_report('sast', artifact).add_finding(high_severity_dast)
    end

    context 'when the target_reports is `nil`' do
      let(:target_reports) { nil }

      it { is_expected.to be(true) }

      context 'with existing vulnerabilities' do
        let!(:finding) do
          create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project,
                                                      uuid: high_severity_dast.uuid)
        end

        it { is_expected.to be(true) }

        context 'with vulnerability states matching existing vulnerabilities' do
          let(:vulnerability_states) { %w[detected] }

          it { is_expected.to be(true) }
        end

        context 'with vulnerability states not matching existing vulnerabilities' do
          let(:vulnerability_states) { %w[resolved] }

          it { is_expected.to be(false) }
        end
      end
    end

    context 'when the target_reports is not `nil`' do
      let(:target_reports) { Gitlab::Ci::Reports::Security::Reports.new(pipeline) }

      context "when a report has a new unsafe vulnerability" do
        context 'with severity levels matching the existing vulnerabilities' do
          it { is_expected.to be(true) }
        end

        context 'with vulnerabilities_allowed higher than the number of new vulnerabilities' do
          let(:vulnerabilities_allowed) { 10000 }

          it { is_expected.to be(false) }
        end

        context "without any severity levels matching the existing vulnerabilities" do
          let(:severity_levels) { %w[critical] }

          it { is_expected.to be(false) }
        end
      end

      context "when none of the reports have a new unsafe vulnerability" do
        before do
          target_reports.get_report('sast', artifact).add_finding(high_severity_dast)
        end

        it { is_expected.to be(false) }

        context 'with existing vulnerabilities' do
          let!(:finding) do
            create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project,
                                                        uuid: high_severity_dast.uuid)
          end

          it { is_expected.to be(false) }

          context 'with vulnerability states matching existing vulnerability' do
            let(:vulnerability_states) { %w[detected] }

            it { is_expected.to be(true) }
          end

          context 'with vulnerability states not matching existing vulnerabilities' do
            let(:vulnerability_states) { %w[resolved] }

            it { is_expected.to be(false) }
          end
        end
      end

      context 'with related report_types' do
        let(:report_types) { %w[sast dast] }

        it { is_expected.to be(true) }
      end

      context 'with unrelated report_types' do
        let(:report_types) { %w[dependency_scanning] }

        it { is_expected.to be(false) }
      end

      context 'when target_reports is not nil and reports is empty' do
        let(:without_reports) { described_class.new(pipeline, []) }

        subject do
          without_reports.violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels,
         vulnerability_states)
        end

        before do
          target_reports.get_report('sast', artifact).add_finding(high_severity_dast)
        end

        context 'when require_approval_on_scan_removal feature is enabled' do
          before do
            stub_feature_flags(require_approval_on_scan_removal: true)
          end

          it { is_expected.to be(true) }
        end

        context 'when require_approval_on_scan_removal feature is disabled' do
          before do
            stub_feature_flags(require_approval_on_scan_removal: false)
          end

          it { is_expected.to be(false) }
        end
      end

      context 'when existing vulnerabilities violate rule' do
        let_it_be(:target_reports) { Gitlab::Ci::Reports::Security::Reports.new(pipeline) }
        let_it_be(:vulnerability_states) { %w[detected] }
        let_it_be(:sast_finding) { build(:ci_reports_security_finding, severity: 'high', report_type: :sast) }

        before(:all) do
          create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project,
                                                      uuid: sast_finding.uuid)

          target_reports.get_report('sast', artifact).add_finding(sast_finding)
        end

        context "with feature disabled" do
          before do
            stub_feature_flags(enforce_scan_result_policies_for_preexisting_vulnerabilities: false)
          end

          it { is_expected.to be(false) }
        end

        context "with feature enabled" do
          before do
            stub_feature_flags(enforce_scan_result_policies_for_preexisting_vulnerabilities: pipeline.project)
          end

          it { is_expected.to be(true) }
        end
      end
    end
  end
end
