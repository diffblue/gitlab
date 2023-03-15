# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OverrideUuidsService, feature_category: :vulnerability_management do
  describe '#execute' do
    let(:vulnerability_finding_uuid_1) { SecureRandom.uuid }
    let(:vulnerability_finding_uuid_2) { SecureRandom.uuid }
    let(:matching_report_finding_uuid_1) { SecureRandom.uuid }
    let(:matching_report_finding_uuid_2) { SecureRandom.uuid }

    let(:pipeline) { create(:ci_pipeline) }
    let(:vulnerability_scanner) { create(:vulnerabilities_scanner, external_id: 'gitlab-sast', project: pipeline.project) }
    let(:vulnerability_identifier) { create(:vulnerabilities_identifier, fingerprint: 'e2bd6788a715674769f48fadffd0bd3ea16656f5') }

    let(:vulnerability_finding_1) do
      create(:vulnerabilities_finding,
             project: pipeline.project,
             uuid: vulnerability_finding_uuid_1,
             location_fingerprint: location_1.fingerprint,
             primary_identifier: vulnerability_identifier,
             scanner: vulnerability_scanner)
    end

    let(:vulnerability_finding_2) do
      create(:vulnerabilities_finding,
             project: pipeline.project,
             uuid: vulnerability_finding_uuid_2,
             location_fingerprint: location_2.fingerprint,
             primary_identifier: vulnerability_identifier,
             scanner: vulnerability_scanner)
    end

    let(:report_scanner) { create(:ci_reports_security_scanner, external_id: 'gitlab-sast') }
    let(:signature_1) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'signature value 1') }
    let(:signature_2) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'signature value 2') }
    let(:signature_3) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'signature value 3') }

    let(:location_1) { create(:ci_reports_security_locations_sast, start_line: 0) }
    let(:location_2) { create(:ci_reports_security_locations_sast, start_line: 1) }

    let(:matching_report_identifier) { create(:ci_reports_security_identifier, external_id: vulnerability_identifier.external_id, external_type: vulnerability_identifier.external_type) }
    let(:matching_report_finding_by_signature) { create(:ci_reports_security_finding, uuid: matching_report_finding_uuid_1, vulnerability_finding_signatures_enabled: true, signatures: [signature_1], identifiers: [matching_report_identifier], scanner: report_scanner) }
    let(:matching_report_finding_by_location) { create(:ci_reports_security_finding, uuid: matching_report_finding_uuid_2, vulnerability_finding_signatures_enabled: true, signatures: [signature_2], location: location_2, identifiers: [matching_report_identifier], scanner: report_scanner) }
    let(:matching_report_finding_by_location_conflict) { create(:ci_reports_security_finding, vulnerability_finding_signatures_enabled: true, signatures: [signature_3], location: location_1, scanner: report_scanner, identifiers: [matching_report_identifier]) }
    let(:unmatching_report_finding) { create(:ci_reports_security_finding, vulnerability_finding_signatures_enabled: true, signatures: [signature_1], scanner: report_scanner) }

    let(:report) do
      create(:ci_reports_security_report,
             findings: [unmatching_report_finding, matching_report_finding_by_signature, matching_report_finding_by_location, matching_report_finding_by_location_conflict],
             pipeline: pipeline)
    end

    let(:service_object) { described_class.new(report) }

    before do
      create(:vulnerabilities_finding_signature, :location, finding: vulnerability_finding_1, signature_sha: Digest::SHA1.digest('signature value 1'))
      create(:vulnerabilities_finding_signature, :location, finding: vulnerability_finding_2, signature_sha: Digest::SHA1.digest('foo'))
    end

    subject(:override_uuids) { service_object.execute }

    it 'overrides finding uuids and prioritizes the existing findings' do
      expect { override_uuids }.to change { report.findings.map(&:overridden_uuid) }.from(Array.new(4) { nil }).to([an_instance_of(String), an_instance_of(String), nil, nil])
                               .and change { matching_report_finding_by_signature.uuid }.from(matching_report_finding_uuid_1).to(vulnerability_finding_uuid_1)
                               .and change { matching_report_finding_by_signature.overridden_uuid }.from(nil).to(matching_report_finding_uuid_1)
                               .and change { matching_report_finding_by_location.uuid }.from(matching_report_finding_uuid_2).to(vulnerability_finding_uuid_2)
                               .and change { matching_report_finding_by_location.overridden_uuid }.from(nil).to(matching_report_finding_uuid_2)
                               .and not_change { matching_report_finding_by_location_conflict.uuid }
                               .and not_change { unmatching_report_finding.uuid }
    end
  end
end
