# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::OverrideUuidsService do
  describe '#execute' do
    let(:vulnerability_finding_uuid) { SecureRandom.uuid }
    let(:report_finding_uuid) { SecureRandom.uuid }
    let(:pipeline) { create(:ci_pipeline) }
    let(:vulnerability_finding) { create(:vulnerabilities_finding, project: pipeline.project, uuid: vulnerability_finding_uuid) }
    let(:signature) { ::Gitlab::Ci::Reports::Security::FindingSignature.new(algorithm_type: 'location', signature_value: 'value') }
    let(:report_finding) { create(:ci_reports_security_finding, uuid: report_finding_uuid, vulnerability_finding_signatures_enabled: true, signatures: [signature]) }
    let(:report) { create(:ci_reports_security_report, findings: [report_finding], pipeline: pipeline) }
    let(:service_object) { described_class.new(report) }

    before do
      create(:vulnerabilities_finding_signature, finding: vulnerability_finding, algorithm_type: 'location', signature_sha: Digest::SHA1.digest('value'))
    end

    subject(:override_uuids) { service_object.execute }

    it 'overrides finding uuids' do
      expect { override_uuids }.to change { report_finding.uuid }.from(report_finding_uuid).to(vulnerability_finding_uuid)
                               .and change { report_finding.overridden_uuid }.from(nil).to(report_finding_uuid)
    end
  end
end
