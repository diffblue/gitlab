# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::IngestReportService, feature_category: :vulnerability_management do
  let(:service_object) { described_class.new(security_scan) }

  describe '#execute' do
    let(:security_scan) { create(:security_scan, :with_findings, scan_type: :sast) }

    subject(:ingest_report) { service_object.execute }

    before do
      create_list(:security_finding, 2, scan: security_scan, deduplicated: true)

      stub_const("#{described_class}::BATCH_SIZE", 1)

      allow(Security::Ingestion::FindingMapCollection).to receive(:new).with(security_scan).and_return([:foo, :bar])
      allow(Security::Ingestion::IngestReportSliceService).to receive(:execute).with(security_scan.pipeline, [:foo]).and_return([1])
      allow(Security::Ingestion::IngestReportSliceService).to receive(:execute).with(security_scan.pipeline, [:bar]).and_return([2])
    end

    it 'calls IngestReportSliceService for each slice of findings and accumulates the return values' do
      expect(ingest_report).to eq([1, 2])

      expect(Security::Ingestion::IngestReportSliceService).to have_received(:execute).twice
    end

    context 'when ingesting vulnerabilities for multiple scanners' do
      let_it_be(:security_scan) { create(:security_scan, scan_type: :dependency_scanning) }
      let_it_be(:artifact) { create(:ee_ci_job_artifact, :dependency_scanning_multiple_scanners, job: security_scan.build, project: security_scan.project) }
      let_it_be(:retirejs_scanner) { create(:vulnerabilities_scanner, project: security_scan.project, external_id: 'retire.js') }
      let_it_be(:gemnasium_scanner) { create(:vulnerabilities_scanner, project: security_scan.project, external_id: 'gemnasium') }
      let_it_be(:other_scanner) { create(:vulnerabilities_scanner, project: security_scan.project, external_id: 'other') }

      it 'resolves the missing vulnerabilities and returns the ingested vulnerability IDs' do
        allow(Security::Ingestion::MarkAsResolvedService).to receive(:execute)

        expect(ingest_report).to eq([1, 2])

        expect(Security::Ingestion::MarkAsResolvedService)
          .to have_received(:execute).once.with(retirejs_scanner, [1, 2])

        expect(Security::Ingestion::MarkAsResolvedService)
          .to have_received(:execute).once.with(gemnasium_scanner, [1, 2])
      end
    end

    context 'when ingesting a slice of vulnerabilities fails' do
      let(:exception) { RuntimeError.new }
      let(:expected_processing_error) { { 'type' => 'IngestionError', 'message' => 'Ingestion failed for some vulnerabilities' } }

      before do
        allow(Security::Ingestion::IngestReportSliceService).to receive(:execute).with(security_scan.pipeline, [:foo]).and_raise(exception)
        allow(Gitlab::ErrorTracking).to receive(:track_exception)
      end

      it 'tracks the exception' do
        ingest_report

        expect(Gitlab::ErrorTracking).to have_received(:track_exception).with(exception)
      end

      it 'captures the error and sets the processing error for security scan record' do
        expect { ingest_report }.to change { security_scan.processing_errors }.from([]).to([expected_processing_error])
      end

      it 'accumulates the return value of only the succeeded executions' do
        expect(ingest_report).to eq([2])
      end
    end
  end
end
