# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::FindingMap, feature_category: :vulnerability_management do
  let(:security_finding) { build(:security_finding) }
  let(:identifier) { build(:ci_reports_security_identifier) }
  let(:report_finding) { build(:ci_reports_security_finding, identifiers: [identifier]) }
  let(:finding_map) { build(:finding_map, security_finding: security_finding, report_finding: report_finding) }

  describe '#uuid' do
    subject { finding_map }

    it { is_expected.to delegate_method(:uuid).to(:security_finding) }
  end

  describe '#identifiers' do
    subject { finding_map.identifiers }

    it { is_expected.to eq([identifier]) }
  end

  describe '#set_identifier_ids_by' do
    let(:identifiers_map) { { identifier.fingerprint => 1 } }

    subject(:set_idenrifier_ids) { finding_map.set_identifier_ids_by(identifiers_map) }

    it 'changes the identifier_ids of the finding_map' do
      expect { set_idenrifier_ids }.to change { finding_map.identifier_ids }.from([]).to([1])
    end
  end

  describe '#issue_feedback' do
    let!(:feedback) do
      create(:vulnerability_feedback,
             :issue,
             project: security_finding.scan.project,
             finding_uuid: security_finding.uuid)
    end

    subject { finding_map.issue_feedback }

    it { is_expected.to eq(feedback) }
  end

  describe '#to_hash' do
    let(:expected_hash) do
      {
        uuid: security_finding.uuid,
        scanner_id: security_finding.scanner_id,
        primary_identifier_id: nil,
        location_fingerprint: report_finding.location.fingerprint,
        project_fingerprint: report_finding.project_fingerprint,
        name: 'Cipher with no integrity',
        report_type: :sast,
        severity: :high,
        confidence: :medium,
        metadata_version: 'sast:1.0',
        details: {},
        raw_metadata: report_finding.raw_metadata,
        description: 'The cipher does not provide data integrity update 1',
        solution: 'GCM mode introduces an HMAC into the resulting encrypted data, providing integrity of the result.',
        message: nil,
        cve: report_finding.cve,
        location: {
          "class" => "com.gitlab.security_products.tests.App",
          "end_line" => 29,
          "file" => "maven/src/main/java/com/gitlab/security_products/tests/App.java",
          "method" => "insecureCypher",
          "start_line" => 29
        }
      }
    end

    subject { finding_map.to_hash }

    it { is_expected.to eq(expected_hash) }
  end
end
