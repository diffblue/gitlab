# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::Tasks::IngestRemediations, feature_category: :vulnerability_management do
  describe '#execute' do
    let(:pipeline) { create(:ci_pipeline) }
    let(:existing_diff) { 'foo' }
    let(:new_diff) { 'bar' }

    let(:existing_checksum) { Digest::SHA256.hexdigest(existing_diff) }
    let(:existing_remediation_1) { create(:vulnerabilities_remediation, project: pipeline.project, checksum: existing_checksum, file: Tempfile.new.tap { _1.write(existing_diff) }, summary: 'Foo Summary') }
    let(:existing_remediation_2) { create(:vulnerabilities_remediation, project: pipeline.project) }

    let(:report_remediation_1) { create(:ci_reports_security_remediation, diff: existing_diff, summary: "Foo Summary") }
    let(:report_remediation_2) { create(:ci_reports_security_remediation, diff: new_diff, summary: "Bar Summary") }

    let(:finding_1) { create(:vulnerabilities_finding, remediations: [existing_remediation_1, existing_remediation_2]) }
    let(:finding_2) { create(:vulnerabilities_finding) }

    let(:report_finding_1) { create(:ci_reports_security_finding, remediations: [report_remediation_1, report_remediation_2]) }
    let(:report_finding_2) { create(:ci_reports_security_finding, remediations: [report_remediation_1, report_remediation_2]) }

    let(:finding_map_1) { create(:finding_map, finding: finding_1, report_finding: report_finding_1) }
    let(:finding_map_2) { create(:finding_map, finding: finding_2, report_finding: report_finding_2) }

    let!(:service_object) { described_class.new(pipeline, [finding_map_1, finding_map_2]) }

    subject(:ingest_finding_remediations) { service_object.execute }

    it 'creates remediations and updates the associations' do
      expect { ingest_finding_remediations }.to change { Vulnerabilities::Remediation.count }.by(1)
                                            .and change { existing_remediation_2.reload.findings }.from([finding_1]).to([])
                                            .and change { finding_2.reload.association(:remediations).scope.count }.from(0).to(2)
                                            .and not_change { finding_1.reload.association(:remediations).scope.count }.from(2)

      expect(finding_2.remediations).to include({ "diff" => existing_diff, "summary" => "Foo Summary" }, { "summary" => "Bar Summary", "diff" => new_diff })
      expect(finding_1.remediations).to include({ "diff" => existing_diff, "summary" => "Foo Summary" }, { "summary" => "Bar Summary", "diff" => new_diff })
    end

    it_behaves_like 'bulk insertable task'
  end
end
