# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Reports::Security::Finding, feature_category: :vulnerability_management do
  using RSpec::Parameterized::TableSyntax

  describe '#initialize' do
    subject { described_class.new(**params) }

    let_it_be(:primary_identifier) { build(:ci_reports_security_identifier) }
    let_it_be(:other_identifier) { build(:ci_reports_security_identifier) }
    let_it_be(:link) { build(:ci_reports_security_link) }
    let_it_be(:scanner) { build(:ci_reports_security_scanner) }
    let_it_be(:location) { build(:ci_reports_security_locations_sast) }
    let_it_be(:evidence) { build(:ci_reports_security_evidence) }
    let_it_be(:remediation) { build(:ci_reports_security_remediation) }

    let(:flag_1) { build(:ci_reports_security_flag) }
    let(:flag_2) { build(:ci_reports_security_flag) }

    let(:params) do
      {
        compare_key: 'this_is_supposed_to_be_a_unique_value',
        confidence: :medium,
        identifiers: [primary_identifier, other_identifier],
        links: [link],
        flags: [flag_1, flag_2],
        remediations: [remediation],
        location: location,
        evidence: evidence,
        metadata_version: 'sast:1.0',
        name: 'Cipher with no integrity',
        original_data: {},
        report_type: :sast,
        scanner: scanner,
        scan: nil,
        severity: :high,
        uuid: 'cadf8cf0a8228fa92a0f4897a0314083bb38',
        details: {
          'commit' => {
            'name' => [
              {
                'lang' => 'en',
                'value' => 'The Commit'
              }
            ],
            'description' => [
              {
                'lang' => 'en',
                'value' => 'Commit where the vulnerability was identified'
              }
            ],
            'type' => 'commit',
            'value' => '41df7b7eb3be2b5be2c406c2f6d28cd6631eeb19'
          }
        }
      }
    end

    context 'when both all params are given' do
      it 'initializes an instance' do
        expect { subject }.not_to raise_error

        expect(subject).to have_attributes(
          compare_key: 'this_is_supposed_to_be_a_unique_value',
          confidence: :medium,
          project_fingerprint: '9a73f32d58d87d94e3dc61c4c1a94803f6014258',
          identifiers: [primary_identifier, other_identifier],
          links: [link],
          flags: [flag_1, flag_2],
          remediations: [remediation],
          location: location,
          evidence: evidence,
          metadata_version: 'sast:1.0',
          name: 'Cipher with no integrity',
          raw_metadata: '{}',
          original_data: {},
          report_type: :sast,
          scanner: scanner,
          severity: :high,
          uuid: 'cadf8cf0a8228fa92a0f4897a0314083bb38',
          details: {
            'commit' => {
              'name' => [
                {
                  'lang' => 'en',
                  'value' => 'The Commit'
                }
              ],
              'description' => [
                {
                  'lang' => 'en',
                  'value' => 'Commit where the vulnerability was identified'
                }
              ],
              'type' => 'commit',
              'value' => '41df7b7eb3be2b5be2c406c2f6d28cd6631eeb19'
            }
          }
        )
      end
    end

    %i[compare_key identifiers location metadata_version name original_data report_type scanner uuid].each do |attribute|
      context "when attribute #{attribute} is missing" do
        before do
          params.delete(attribute)
        end

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end
    end
  end

  describe "delegation" do
    subject { create(:ci_reports_security_finding) }

    %i[file_path start_line end_line].each do |attribute|
      it "delegates attribute #{attribute} to location" do
        expect(subject.public_send(attribute)).to eq(subject.location.public_send(attribute))
      end
    end
  end

  describe '#to_hash' do
    let(:occurrence) { create(:ci_reports_security_finding) }

    subject { occurrence.to_hash }

    it 'returns expected hash' do
      is_expected.to eq({
        compare_key: occurrence.compare_key,
        confidence: occurrence.confidence,
        identifiers: occurrence.identifiers,
        links: occurrence.links,
        flags: occurrence.flags,
        location: occurrence.location,
        evidence: occurrence.evidence,
        metadata_version: occurrence.metadata_version,
        name: occurrence.name,
        project_fingerprint: occurrence.project_fingerprint,
        raw_metadata: occurrence.raw_metadata,
        report_type: occurrence.report_type,
        scanner: occurrence.scanner,
        scan: occurrence.scan,
        severity: occurrence.severity,
        uuid: occurrence.uuid,
        details: occurrence.details,
        cve: occurrence.compare_key,
        description: occurrence.description,
        message: occurrence.message,
        solution: occurrence.solution,
        signatures: []
      })
    end
  end

  describe '#primary_identifier' do
    let(:primary_identifier) { create(:ci_reports_security_identifier) }
    let(:other_identifier) { create(:ci_reports_security_identifier) }

    let(:occurrence) { create(:ci_reports_security_finding, identifiers: [primary_identifier, other_identifier]) }

    subject { occurrence.primary_identifier }

    it 'returns the first identifier' do
      is_expected.to eq(primary_identifier)
    end
  end

  describe '#update_location' do
    let(:old_location) { create(:ci_reports_security_locations_sast, file_path: 'old_file.rb') }
    let(:new_location) { create(:ci_reports_security_locations_sast, file_path: 'new_file.rb') }

    let(:occurrence) { create(:ci_reports_security_finding, location: old_location) }

    subject { occurrence.update_location(new_location) }

    it 'assigns the new location and returns it' do
      subject

      expect(occurrence.location).to eq(new_location)
      is_expected.to eq(new_location)
    end

    it 'assigns the old location' do
      subject

      expect(occurrence.old_location).to eq(old_location)
    end
  end

  describe '#unsafe?' do
    where(:severity, :levels, :report_types, :unsafe?) do
      'critical' | %w(critical high) | %w(dast)               | true
      'high'     | %w(critical high) | %w(dast sast)          | true
      'high'     | %w(critical high) | %w(container_scanning) | false
      'medium'   | %w(critical high) | %w(dast)               | false
      'low'      | %w(critical high) | %w(dast)               | false
      'info'     | %w(critical high) | %w(dast)               | false
      'unknown'  | []                | %w(dast)               | false
    end

    with_them do
      let(:finding) { create(:ci_reports_security_finding, severity: severity, report_type: 'dast') }

      subject { finding.unsafe?(levels, report_types) }

      it { is_expected.to be(unsafe?) }
    end
  end

  describe '#eql?' do
    where(vulnerability_finding_signatures_enabled: [true, false])
    with_them do
      let(:identifier) { build(:ci_reports_security_identifier) }
      let(:location) { build(:ci_reports_security_locations_sast) }
      let(:finding) { build(:ci_reports_security_finding, severity: 'low', report_type: :sast, identifiers: [identifier], location: location, vulnerability_finding_signatures_enabled: vulnerability_finding_signatures_enabled) }

      let(:report_type) { :secret_detection }
      let(:identifier_external_id) { 'foo' }
      let(:location_start_line) { 0 }
      let(:other_identifier) { build(:ci_reports_security_identifier, external_id: identifier_external_id) }
      let(:other_location) { build(:ci_reports_security_locations_sast, start_line: location_start_line) }
      let(:other_finding) do
        build(:ci_reports_security_finding,
              severity: 'low',
              report_type: report_type,
              identifiers: [other_identifier],
              location: other_location,
              vulnerability_finding_signatures_enabled: vulnerability_finding_signatures_enabled)
      end

      let(:signature) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'value1') }

      subject { finding.eql?(other_finding) }

      context 'when the primary_identifier is nil' do
        let(:identifier) { nil }

        it 'does not raise an exception' do
          expect { subject }.not_to raise_error
        end
      end

      context 'when the other finding has same `report_type`' do
        let(:report_type) { :sast }

        context 'when the other finding has same primary identifier fingerprint' do
          let(:identifier_external_id) { identifier.external_id }

          context 'when the other finding has same location signature' do
            before do
              finding.signatures << signature
              other_finding.signatures << signature
            end

            let(:location_start_line) { location.start_line }

            it { is_expected.to be(true) }
          end

          context 'when the other finding does not have same location signature' do
            it { is_expected.to be(false) }
          end
        end

        context 'when the other finding does not have same primary identifier fingerprint' do
          context 'when the other finding has same location signature' do
            let(:location_start_line) { location.start_line }

            it { is_expected.to be(false) }
          end

          context 'when the other finding does not have same location signature' do
            it { is_expected.to be(false) }
          end
        end
      end

      context 'when the other finding does not have same `report_type`' do
        context 'when the other finding has same primary identifier fingerprint' do
          let(:identifier_external_id) { identifier.external_id }

          context 'when the other finding has same location signature' do
            let(:location_start_line) { location.start_line }

            it { is_expected.to be(false) }
          end

          context 'when the other finding does not have same location signature' do
            it { is_expected.to be(false) }
          end
        end

        context 'when the other finding does not have same primary identifier fingerprint' do
          context 'when the other finding has same location signature' do
            let(:location_start_line) { location.start_line }

            it { is_expected.to be(false) }
          end

          context 'when the other finding does not have same location signature' do
            it { is_expected.to be(false) }
          end
        end
      end
    end
  end

  describe '#valid?' do
    let(:scanner) { build(:ci_reports_security_scanner) }
    let(:identifiers) { [build(:ci_reports_security_identifier)] }
    let(:location) { build(:ci_reports_security_locations_sast) }
    let(:uuid) { SecureRandom.uuid }

    let(:finding) do
      build(:ci_reports_security_finding,
            scanner: scanner,
            identifiers: identifiers,
            location: location,
            uuid: uuid,
            compare_key: '')
    end

    subject { finding.valid? }

    context 'when the scanner is missing' do
      let(:scanner) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when there is no identifier' do
      let(:identifiers) { [] }

      it { is_expected.to be_falsey }
    end

    context 'when the location is missing' do
      let(:location) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when the uuid is missing' do
      let(:uuid) { nil }

      it { is_expected.to be_falsey }
    end

    context 'when all required attributes present' do
      it { is_expected.to be_truthy }
    end
  end

  describe '#keys' do
    let(:identifier_1) { build(:ci_reports_security_identifier) }
    let(:identifier_2) { build(:ci_reports_security_identifier) }
    let(:location) { build(:ci_reports_security_locations_sast) }
    let(:signature) { build(:ci_reports_security_finding_signature, signature_value: 'value') }
    let(:finding) { build(:ci_reports_security_finding, identifiers: [identifier_1, identifier_2], location: location, vulnerability_finding_signatures_enabled: true, signatures: [signature]) }
    let(:expected_keys) do
      [
        finding.uuid,
        build(:ci_reports_security_finding_key, location_fingerprint: location.fingerprint, identifier_fingerprint: identifier_1.fingerprint),
        build(:ci_reports_security_finding_key, location_fingerprint: location.fingerprint, identifier_fingerprint: identifier_2.fingerprint),
        build(:ci_reports_security_finding_key, location_fingerprint: signature.signature_hex, identifier_fingerprint: identifier_1.fingerprint),
        build(:ci_reports_security_finding_key, location_fingerprint: signature.signature_hex, identifier_fingerprint: identifier_2.fingerprint)
      ]
    end

    subject { finding.keys }

    it { is_expected.to match_array(expected_keys) }
  end

  describe '#hash' do
    let(:scanner) { build(:ci_reports_security_scanner) }
    let(:identifiers) { [build(:ci_reports_security_identifier)] }
    let(:location) { build(:ci_reports_security_locations_sast) }
    let(:uuid) { SecureRandom.uuid }

    context 'with vulnerability_finding_signatures enabled' do
      let(:finding) do
        build(:ci_reports_security_finding,
              scanner: scanner,
              identifiers: identifiers,
              location: location,
              uuid: uuid,
              compare_key: '',
              vulnerability_finding_signatures_enabled: true)
      end

      let(:low_priority_signature) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'value1') }
      let(:high_priority_signature) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'scope_offset', signature_value: 'value2') }

      it 'returns the expected hash with no signatures' do
        expect(finding.signatures.length).to eq(0)
        expect(finding.hash).to eq(finding.report_type.hash ^ finding.location.fingerprint.hash ^ finding.primary_identifier_fingerprint.hash)
      end

      it 'returns the expected hash with signatures' do
        finding.signatures << low_priority_signature
        finding.signatures << high_priority_signature

        expect(finding.signatures.length).to eq(2)
        expect(finding.hash).to eq(finding.report_type.hash ^ high_priority_signature.signature_hex.hash ^ finding.primary_identifier_fingerprint.hash)
      end
    end

    context 'without vulnerability_finding_signatures enabled' do
      let(:finding) do
        build(:ci_reports_security_finding,
              scanner: scanner,
              identifiers: identifiers,
              location: location,
              uuid: uuid,
              compare_key: '',
              vulnerability_finding_signatures_enabled: false)
      end

      it 'returns the expected hash' do
        expect(finding.hash).to eq(finding.report_type.hash ^ finding.location.fingerprint.hash ^ finding.primary_identifier_fingerprint.hash)
      end
    end
  end

  describe '#scanner_order_to' do
    let(:scanner_1) { build(:ci_reports_security_scanner) }
    let(:scanner_2) { build(:ci_reports_security_scanner) }
    let(:finding_1) { build(:ci_reports_security_finding, scanner: scanner_1) }
    let(:finding_2) { build(:ci_reports_security_finding, scanner: scanner_2) }

    subject(:compare_based_on_scanners) { finding_1.scanner_order_to(finding_2) }

    context 'when the scanner of the receiver is nil' do
      let(:scanner_1) { nil }

      context 'when the scanner of the other is nil' do
        let(:scanner_2) { nil }

        it { is_expected.to be(1) }
      end

      context 'when the scanner of the other is not nil' do
        it { is_expected.to be(1) }
      end
    end

    context 'when the scanner of the receiver is not nil' do
      context 'when the scanner of the other is nil' do
        let(:scanner_2) { nil }

        it { is_expected.to be(-1) }
      end

      context 'when the scanner of the other is not nil' do
        before do
          allow(scanner_1).to receive(:<=>).and_return(0)
        end

        it 'compares two scanners' do
          expect(compare_based_on_scanners).to be(0)
          expect(scanner_1).to have_received(:<=>).with(scanner_2)
        end
      end
    end
  end

  describe '#<=>' do
    let(:finding_1) { build(:ci_reports_security_finding, severity: :critical, compare_key: 'b') }
    let(:finding_2) { build(:ci_reports_security_finding, severity: :critical, compare_key: 'a') }
    let(:finding_3) { build(:ci_reports_security_finding, severity: :high) }

    subject { [finding_1, finding_2, finding_3].sort }

    it { is_expected.to eq([finding_2, finding_1, finding_3]) }
  end

  describe '#location_fingerprint' do
    let(:signature_1) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'value1') }
    let(:signature_2) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'scope_offset', signature_value: 'value2') }
    let(:location) { build(:ci_reports_security_locations_sast) }
    let(:finding) { build(:ci_reports_security_finding, vulnerability_finding_signatures_enabled: signatures_enabled, signatures: signatures, location: location) }

    let(:fingerprint_from_location) { location.fingerprint }
    let(:fingerprint_from_signature) { signature_2.signature_hex }

    subject { finding.location_fingerprint }

    context 'when the signatures feature is enabled' do
      let(:signatures_enabled) { true }

      context 'when the signatures are empty' do
        let(:signatures) { [] }

        it { is_expected.to eq(fingerprint_from_location) }
      end

      context 'when the signatures are not empty' do
        let(:signatures) { [signature_1, signature_2] }

        it { is_expected.to eq(fingerprint_from_signature) }
      end
    end

    context 'when the signatures feature is not enabled' do
      let(:signatures_enabled) { false }

      context 'when the signatures are empty' do
        let(:signatures) { [] }

        it { is_expected.to eq(fingerprint_from_location) }
      end

      context 'when the signatures are not empty' do
        let(:signatures) { [signature_1, signature_2] }

        it { is_expected.to eq(fingerprint_from_location) }
      end
    end
  end

  describe '#false_positive?' do
    let(:flag) { instance_double(Gitlab::Ci::Reports::Security::Flag, false_positive?: flag_false_positive?) }
    let(:finding) { build(:ci_reports_security_finding, flags: [flag]) }

    subject { finding.false_positive? }

    context 'when the finding does not have a false positive flag' do
      let(:flag_false_positive?) { false }

      it { is_expected.to be_falsey }
    end

    context 'when the finding has a false positive flag' do
      let(:flag_false_positive?) { true }

      it { is_expected.to be_truthy }
    end
  end

  describe '#remediation_byte_offsets' do
    let(:remediation) { build(:ci_reports_security_remediation, start_byte: 0, end_byte: 100) }
    let(:finding) { build(:ci_reports_security_finding, remediations: [remediation]) }

    subject { finding.remediation_byte_offsets }

    it { is_expected.to match_array([{ start_byte: 0, end_byte: 100 }]) }
  end

  describe '#assets' do
    let(:finding) { build(:ci_reports_security_finding, original_data: original_data) }

    subject { finding.assets }

    context 'when the original data does not have assets' do
      let(:original_data) { {} }

      it { is_expected.to be_empty }
    end

    context 'when the original data has assets' do
      let(:assets) { [{ 'name' => 'Test asset', 'type' => 'type', 'url' => 'example.com' }] }
      let(:original_data) { { 'assets' => assets } }

      it { is_expected.to eq(assets) }
    end
  end

  describe '#raw_source_code_extract' do
    let(:original_data) { { 'raw_source_code_extract' => 'leaked-secret' } }
    let(:finding) { build(:ci_reports_security_finding, original_data: original_data) }

    subject { finding.raw_source_code_extract }

    it { is_expected.to eq(original_data['raw_source_code_extract']) }
  end
end
