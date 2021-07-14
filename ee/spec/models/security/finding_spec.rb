# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Finding do
  let_it_be(:scan_1) { create(:security_scan, scan_type: :sast) }
  let_it_be(:scan_2) { create(:security_scan, scan_type: :dast) }
  let_it_be(:finding_1) { create(:security_finding, scan: scan_1) }
  let_it_be(:finding_2) { create(:security_finding, scan: scan_2) }

  describe 'associations' do
    it { is_expected.to belong_to(:scan).required }
    it { is_expected.to belong_to(:scanner).required }
    it { is_expected.to have_one(:build).through(:scan) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:uuid) }
  end

  describe 'delegations' do
    it { is_expected.to delegate_method(:scan_type).to(:scan).allow_nil }
  end

  describe '.by_uuid' do
    let(:expected_findings) { [finding_1] }

    subject { described_class.by_uuid(finding_1.uuid) }

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_build_ids' do
    subject { described_class.by_build_ids(finding_1.scan.build_id) }

    it { is_expected.to eq([finding_1]) }
  end

  describe '.by_severity_levels' do
    let(:expected_findings) { [finding_2] }

    subject { described_class.by_severity_levels(:critical) }

    before do
      finding_1.update! severity: :high
      finding_2.update! severity: :critical
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_confidence_levels' do
    let(:expected_findings) { [finding_2] }

    subject { described_class.by_confidence_levels(:high) }

    before do
      finding_1.update! confidence: :low
      finding_2.update! confidence: :high
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_report_types' do
    let(:expected_findings) { [finding_1] }

    subject { described_class.by_report_types(:sast) }

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.by_project_fingerprints' do
    let(:expected_findings) { [finding_1] }

    subject { described_class.by_project_fingerprints(finding_1.project_fingerprint) }

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.undismissed' do
    let(:expected_findings) { [finding_2] }

    subject { described_class.undismissed }

    before do
      finding_2.update! scan: scan_1

      create(:vulnerability_feedback,
             :dismissal,
             project: scan_1.project,
             category: scan_1.scan_type,
             project_fingerprint: finding_1.project_fingerprint)

      create(:vulnerability_feedback,
             :dismissal,
             project: scan_2.project,
             category: scan_2.scan_type,
             project_fingerprint: finding_2.project_fingerprint)
    end

    it { is_expected.to match_array(expected_findings) }
  end

  describe '.ordered' do
    let_it_be(:finding_3) { create(:security_finding, severity: :critical, confidence: :confirmed) }
    let_it_be(:finding_4) { create(:security_finding, severity: :critical, confidence: :high) }

    let(:expected_findings) { [finding_3, finding_4, finding_1, finding_2] }

    subject { described_class.ordered }

    before do
      finding_1.update!(severity: :high, confidence: :unknown)
      finding_2.update!(severity: :low, confidence: :confirmed)
    end

    it { is_expected.to eq(expected_findings) }
  end

  describe '.deduplicated' do
    let(:expected_findings) { [finding_1] }

    subject { described_class.deduplicated }

    before do
      finding_1.update! deduplicated: true
      finding_2.update! deduplicated: false
    end

    it { is_expected.to eq(expected_findings) }
  end

  describe '.count_by_scan_type' do
    subject { described_class.count_by_scan_type }

    let_it_be(:finding_3) { create(:security_finding, scan: scan_1) }

    it {
      is_expected.to eq({
        Security::Scan.scan_types['dast'] => 1,
        Security::Scan.scan_types['sast'] => 2
      })
    }
  end
end
