# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Reports, feature_category: :vulnerability_management do
  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:ci_build) { create(:ci_build, :success, name: 'sast', pipeline: pipeline) }
  let_it_be(:sast_artifact) { create(:ci_job_artifact, :sast, job: ci_build) }
  let_it_be(:scan) { create(:security_scan, :latest_successful, scan_type: :sast, build: ci_build) }

  let(:security_reports) { described_class.new(pipeline) }

  describe "#violates_default_policy_against?" do
    let(:high_severity_sast) { build(:ci_reports_security_finding, severity: 'high', report_type: :sast) }
    let(:vulnerabilities_allowed) { 0 }
    let(:severity_levels) { %w(critical high) }
    let(:vulnerability_states) { %w(newly_detected) }
    let(:report_types) { [] }

    subject(:reports_violate_policy?) { security_reports.violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels, vulnerability_states, report_types) }

    before do
      security_reports.get_report('sast', sast_artifact).add_finding(high_severity_sast)
    end

    context 'when the target_reports is `nil`' do
      let(:target_reports) { nil }

      it { is_expected.to be(true) }

      context 'with existing vulnerabilities' do
        let!(:finding) { create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project, uuid: high_severity_sast.uuid) }

        it { is_expected.to be(true) }

        context 'with vulnerability states matching existing vulnerabilities' do
          let(:vulnerability_states) { %w(detected) }

          it { is_expected.to be(true) }
        end

        context 'with vulnerability states not matching existing vulnerabilities' do
          let(:vulnerability_states) { %w(resolved) }

          it { is_expected.to be(false) }
        end
      end
    end

    context 'when the target_reports is not `nil`' do
      let(:target_reports) { described_class.new(pipeline) }

      context "when a report has a new unsafe vulnerability" do
        context 'with severity levels matching the existing vulnerabilities' do
          it { is_expected.to be(true) }
        end

        context 'with vulnerability states matching new vulnerabilities' do
          using RSpec::Parameterized::TableSyntax

          where(:filtering_states, :result) do
            %w(new_dismissed) | true
            %w(new_needs_triage) | true
            %w(new_dismissed new_needs_triage) | true
          end

          with_them do
            let(:vulnerability_states) { filtering_states }

            it { is_expected.to be(result) }
          end
        end

        context 'with vulnerabilities_allowed higher than the number of new vulnerabilities' do
          let(:vulnerabilities_allowed) { 10000 }

          it { is_expected.to be(false) }
        end

        context "without any severity levels matching the existing vulnerabilities" do
          let(:severity_levels) { %w(critical) }

          it { is_expected.to be(false) }
        end

        context 'when the new vulnerability was dismissed' do
          let!(:finding) { create(:vulnerabilities_finding, :dismissed, report_type: :sast, project: pipeline.project, uuid: high_severity_sast.uuid) }

          before do
            create(:security_finding,
                   severity: finding.severity,
                   confidence: finding.confidence,
                   project_fingerprint: finding.project_fingerprint,
                   deduplicated: true,
                   scan: scan,
                   uuid: finding.uuid)
          end

          context 'when filtering by new_needs_triage' do
            let(:vulnerability_states) { %w(new_needs_triage) }

            it { is_expected.to be(false) }
          end
        end
      end

      context "when none of the reports have a new unsafe vulnerability" do
        before do
          target_reports.get_report('sast', sast_artifact).add_finding(high_severity_sast)
        end

        it { is_expected.to be(false) }

        context 'with existing vulnerabilities' do
          let!(:finding) { create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project, uuid: high_severity_sast.uuid) }

          it { is_expected.to be(false) }

          context 'with vulnerability states matching existing vulnerability' do
            let(:vulnerability_states) { %w(detected) }

            it { is_expected.to be(true) }
          end

          context 'with vulnerability states not matching existing vulnerabilities' do
            let(:vulnerability_states) { %w(resolved) }

            it { is_expected.to be(false) }

            context 'when filtering by new_dismissed' do
              let(:vulnerability_states) { %w(new_dismissed) }

              it { is_expected.to be(false) }
            end

            context 'when filtering by new_needs_triage' do
              let(:vulnerability_states) { %w(new_needs_triage) }

              it { is_expected.to be(false) }
            end

            context 'when filtering by new_dismissed and new_needs_triage' do
              let(:vulnerability_states) { %w(new_dismissed new_needs_triage) }

              it { is_expected.to be(false) }
            end
          end
        end
      end

      context 'with related report_types' do
        let(:report_types) { %w(sast dast) }

        it { is_expected.to be(true) }
      end

      context 'with unrelated report_types' do
        let(:report_types) { %w(dependency_scanning) }

        it { is_expected.to be(false) }
      end

      context 'when target_reports is not nil and reports is empty' do
        let(:without_reports) { described_class.new(pipeline) }

        subject { without_reports.violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels, vulnerability_states) }

        before do
          target_reports.get_report('sast', sast_artifact).add_finding(high_severity_sast)
        end

        it { is_expected.to be(true) }
      end

      context 'when existing vulnerabilities violate rule' do
        let_it_be(:target_reports) { described_class.new(pipeline) }
        let_it_be(:vulnerability_states) { %w[detected] }
        let_it_be(:sast_finding) { build(:ci_reports_security_finding, severity: 'high', report_type: :sast) }

        before(:all) do
          create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project,
                                                      uuid: sast_finding.uuid)

          target_reports.get_report('sast', sast_artifact).add_finding(sast_finding)
        end

        before do
          stub_const("::Gitlab::Ci::Reports::Security::Concerns::ScanFinding::COUNT_BATCH_SIZE", 1)

          another_sast_finding = build(:ci_reports_security_finding, severity: 'high', report_type: :sast)

          security_reports.get_report('sast', sast_artifact).add_finding(another_sast_finding)
        end

        it { is_expected.to be(true) }

        it 'runs in batches' do
          expect(::Vulnerability).to receive(:with_findings_by_uuid_and_state).exactly(3).times.and_call_original

          reports_violate_policy?
        end
      end
    end
  end
end
