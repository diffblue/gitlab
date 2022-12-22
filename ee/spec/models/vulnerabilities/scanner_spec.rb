# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Vulnerabilities::Scanner, feature_category: :vulnerability_management do
  describe 'associations' do
    it { is_expected.to belong_to(:project) }
    it { is_expected.to have_many(:findings).class_name('Vulnerabilities::Finding') }
    it { is_expected.to have_many(:security_findings).class_name('Security::Finding') }
  end

  describe 'validations' do
    let!(:scanner) { create(:vulnerabilities_scanner) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_presence_of(:external_id) }
    it { is_expected.to validate_uniqueness_of(:external_id).scoped_to(:project_id) }
    it { is_expected.to validate_length_of(:vendor).is_at_most(255) }
  end

  describe '.with_external_id' do
    let(:external_id) { 'bandit' }

    subject { described_class.with_external_id(external_id) }

    context 'when scanner has the corresponding external_id' do
      let!(:scanner) { create(:vulnerabilities_scanner, external_id: external_id) }

      it 'selects the scanner' do
        is_expected.to eq([scanner])
      end
    end

    context 'when scanner does not have the corresponding external_id' do
      let!(:scanner) { create(:vulnerabilities_scanner) }

      it 'does not select the scanner' do
        is_expected.to be_empty
      end
    end
  end

  describe '.report_type' do
    let(:report_type) { 'sast' }
    let(:scan_type) { 'dast' }
    let(:report_type_value) { ::Enums::Vulnerability.report_types[report_type] }
    let(:scan_type_value) { ::Enums::Vulnerability.report_types[scan_type] }
    let(:scanner) { create(:vulnerabilities_scanner, scan_type: scan_type_value) }
    let!(:finding) { create(:vulnerabilities_finding, scanner: scanner, report_type: report_type) }

    context 'when the scanner has a report type attribute' do
      let(:finding) { create(:vulnerabilities_finding, scanner: scanner) }

      it 'returns the attribute value' do
        found_scanner = described_class.with_report_type.find(scanner.id)
        expect(found_scanner.report_type).to eq(report_type_value)
      end
    end

    context 'when the scanner does not have a report type attribute' do
      it 'returns the scan_type value' do
        expect(scanner.report_type).to eq(scan_type_value)
      end
    end
  end
end
