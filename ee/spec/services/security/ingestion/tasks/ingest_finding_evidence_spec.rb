# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestFindingEvidence, feature_category: :vulnerability_management do
  describe '#execute' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:finding_evidence) { create(:ci_reports_security_evidence) }
    let(:finding_1) { create(:vulnerabilities_finding) }
    let(:finding_2) { create(:vulnerabilities_finding) }
    let(:report_finding_1) { create(:ci_reports_security_finding, evidence: finding_evidence) }
    let(:report_finding_2) { create(:ci_reports_security_finding, evidence: finding_evidence) }
    let(:finding_map_1) { create(:finding_map, finding: finding_1, report_finding: report_finding_1) }
    let(:finding_map_2) { create(:finding_map, finding: finding_2, report_finding: report_finding_2) }
    let(:service_object) { described_class.new(pipeline, [finding_map_1, finding_map_2]) }

    subject(:ingest_finding_evidence) { service_object.execute }

    it 'creates finding evidence for the new records' do
      expect { ingest_finding_evidence }.to change { Vulnerabilities::Finding::Evidence.count }.by(2)
    end
  end
end
