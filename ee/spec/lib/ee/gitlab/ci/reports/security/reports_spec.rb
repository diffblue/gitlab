# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Reports do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:artifact) { create(:ci_job_artifact, :sast) }

  let(:security_reports) { described_class.new(pipeline) }

  describe "#violates_default_policy_against?" do
    let(:high_severity_dast) { build(:ci_reports_security_finding, severity: 'high', report_type: :dast) }
    let(:vulnerabilities_allowed) { 0 }
    let(:severity_levels) { %w(critical high) }
    let(:vulnerability_states) { %w(newly_detected) }

    subject { security_reports.violates_default_policy_against?(target_reports, vulnerabilities_allowed, severity_levels, vulnerability_states) }

    before do
      security_reports.get_report('sast', artifact).add_finding(high_severity_dast)
    end

    context 'when the target_reports is `nil`' do
      let(:target_reports) { nil }

      it { is_expected.to be(true) }

      context 'with existing vulnerabilities' do
        let!(:finding) { create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project, uuid: high_severity_dast.uuid) }

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

      it { is_expected.to be(true) }

      context "when none of the reports have a new unsafe vulnerability" do
        before do
          target_reports.get_report('sast', artifact).add_finding(high_severity_dast)
        end

        it { is_expected.to be(false) }

        context 'with existing vulnerabilities' do
          let!(:finding) { create(:vulnerabilities_finding, :detected, report_type: :sast, project: pipeline.project, uuid: high_severity_dast.uuid) }

          it { is_expected.to be(false) }

          context 'with vulnerability states matching existing vulnerability' do
            let(:vulnerability_states) { %w(detected) }

            it { is_expected.to be(true) }
          end

          context 'with vulnerability states not matching existing vulnerabilities' do
            let(:vulnerability_states) { %w(resolved) }

            it { is_expected.to be(false) }
          end
        end
      end
    end
  end
end
