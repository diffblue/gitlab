# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::IngestReportsService do
  let(:service_object) { described_class.new(pipeline) }

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:security_scan_1) { create(:security_scan, build: build, scan_type: :sast) }
  let_it_be(:security_scan_2) { create(:security_scan, :with_error, build: build, scan_type: :dast) }
  let_it_be(:security_scan_3) { create(:security_scan, build: build, scan_type: :secret_detection) }
  let_it_be(:vulnerability_1) { create(:vulnerability, project: pipeline.project) }
  let_it_be(:vulnerability_2) { create(:vulnerability, project: pipeline.project) }

  describe '#execute' do
    let(:ids_1) { [vulnerability_1.id] }
    let(:ids_2) { [] }

    subject(:ingest_reports) { service_object.execute }

    before do
      allow(Security::Ingestion::IngestReportService).to receive(:execute).and_return(ids_1, ids_2)
    end

    it 'calls IngestReportService for each succeeded security scan' do
      ingest_reports

      expect(Security::Ingestion::IngestReportService).to have_received(:execute).twice
      expect(Security::Ingestion::IngestReportService).to have_received(:execute).once.with(security_scan_1)
      expect(Security::Ingestion::IngestReportService).to have_received(:execute).once.with(security_scan_3)
    end

    it 'sets the resolved vulnerabilities, latest pipeline ID and has_vulnerabilities flag' do
      expect { ingest_reports }.to change { project.reload.project_setting&.has_vulnerabilities }.to(true)
                               .and change { project.reload.vulnerability_statistic&.latest_pipeline_id }.to(pipeline.id)
                               .and change { vulnerability_2.reload.resolved_on_default_branch }.from(false).to(true)
                               .and not_change { vulnerability_1.reload.resolved_on_default_branch }.from(false)
    end
  end
end
