# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OverrideUuidsService do
  describe '#execute' do
    let(:vulnerability_finding_uuid) { SecureRandom.uuid }
    let(:matching_report_finding_uuid) { SecureRandom.uuid }

    let(:pipeline) { create(:ci_pipeline) }
    let(:vulnerability_scanner) { create(:vulnerabilities_scanner, external_id: 'gitlab-sast', project: pipeline.project) }
    let(:vulnerability_identifier) { create(:vulnerabilities_identifier, fingerprint: 'e2bd6788a715674769f48fadffd0bd3ea16656f5') }
    let(:vulnerability_finding) { create(:vulnerabilities_finding, project: pipeline.project, uuid: vulnerability_finding_uuid, primary_identifier: vulnerability_identifier, scanner: vulnerability_scanner) }

    let(:signature) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'value') }
    let(:report_scanner) { create(:ci_reports_security_scanner, external_id: 'gitlab-sast') }
    let(:matching_report_identifier) { create(:ci_reports_security_identifier, external_id: vulnerability_identifier.external_id, external_type: vulnerability_identifier.external_type) }
    let(:matching_report_finding) { create(:ci_reports_security_finding, uuid: matching_report_finding_uuid, vulnerability_finding_signatures_enabled: true, signatures: [signature], identifiers: [matching_report_identifier], scanner: report_scanner) }
    let(:unmatching_report_finding) { create(:ci_reports_security_finding, vulnerability_finding_signatures_enabled: true, signatures: [signature], scanner: report_scanner) }
    let(:report) { create(:ci_reports_security_report, findings: [matching_report_finding, unmatching_report_finding], pipeline: pipeline) }

    let(:service_object) { described_class.new(report) }

    before do
      create(:vulnerabilities_finding_signature, finding: vulnerability_finding, algorithm_type: 'location', signature_sha: Digest::SHA1.digest('value'))
    end

    subject(:override_uuids) { service_object.execute }

    it 'overrides finding uuids' do
      expect { override_uuids }.to change { matching_report_finding.uuid }.from(matching_report_finding_uuid).to(vulnerability_finding_uuid)
                               .and change { matching_report_finding.overridden_uuid }.from(nil).to(matching_report_finding_uuid)
                               .and not_change { unmatching_report_finding.uuid }
    end
  end
end
