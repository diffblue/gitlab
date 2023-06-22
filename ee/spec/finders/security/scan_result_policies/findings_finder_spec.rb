# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::ScanResultPolicies::FindingsFinder, feature_category: :security_policy_management do
  let_it_be(:pipeline) { create(:ee_ci_pipeline) }
  let_it_be(:project) { pipeline.project }

  let_it_be(:dependency_scan) { create(:security_scan, pipeline: pipeline, scan_type: 'dependency_scanning') }
  let_it_be(:container_scan) { create(:security_scan, pipeline: pipeline, scan_type: 'container_scanning') }

  let_it_be(:high_severity_finding) { create(:security_finding, scan: dependency_scan, severity: 'high') }
  let_it_be(:container_scanning_finding) { create(:security_finding, scan: container_scan) }
  let_it_be(:dismissed_finding) { create(:security_finding, scan: dependency_scan) }

  before do
    create(:vulnerabilities_finding, :dismissed, uuid: dismissed_finding.uuid)

    create(:vulnerability_feedback, :dismissal,
      project: dependency_scan.project,
      category: dependency_scan.scan_type,
      finding_uuid: dismissed_finding.uuid
    )
  end

  describe '#execute' do
    subject { described_class.new(pipeline, params).execute }

    context 'with severity_levels' do
      let(:params) { { severity_levels: ['high'] } }

      it { is_expected.to contain_exactly(high_severity_finding) }

      context 'when it is an empty array' do
        let(:params) { { severity_levels: [] } }

        it { is_expected.to contain_exactly(high_severity_finding, container_scanning_finding, dismissed_finding) }
      end
    end

    context 'with scanners' do
      let(:params) { { scanners: ['container_scanning'] } }

      it { is_expected.to contain_exactly(container_scanning_finding) }
    end

    context 'with undismissed findings' do
      context 'when check_dismissed is true' do
        let(:params) { { check_dismissed: true, vulnerability_states: ['new_needs_triage'] } }

        it { is_expected.to contain_exactly(high_severity_finding, container_scanning_finding) }

        context 'when deprecate_vulnerabilities_feedback is disabled' do
          before do
            stub_feature_flags(deprecate_vulnerabilities_feedback: false)
          end

          it { is_expected.to contain_exactly(high_severity_finding, container_scanning_finding) }
        end
      end

      context 'when check_dismissed is false' do
        let(:params) { { check_dismissed: false, vulnerability_states: ['new_needs_triage'] } }

        it {
          is_expected.to contain_exactly(
            high_severity_finding, container_scanning_finding, dismissed_finding
          )
        }
      end
    end

    context 'with dismissed findings' do
      context 'when check_dismissed is true' do
        let(:params) { { check_dismissed: true, vulnerability_states: ['new_dismissed'] } }

        it { is_expected.to contain_exactly(dismissed_finding) }
      end

      context 'when check_dismissed is false' do
        let(:params) { { check_dismissed: false, vulnerability_states: ['new_dismissed'] } }

        it {
          is_expected.to contain_exactly(
            high_severity_finding, container_scanning_finding, dismissed_finding
          )
        }
      end
    end
  end
end
