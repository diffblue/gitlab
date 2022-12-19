# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Security::Ingestion::IngestReportsService do
  let(:service_object) { described_class.new(pipeline) }

  let_it_be(:project) { create(:project) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, pipeline: pipeline) }
  let_it_be(:security_scan_1) { create(:security_scan, build: build, scan_type: :sast) }
  let_it_be(:security_scan_2) { create(:security_scan, :with_error, build: build, scan_type: :dast) }
  let_it_be(:security_scan_3) { create(:security_scan, build: build, scan_type: :dependency_scanning) }
  let_it_be(:vulnerability_1) { create(:vulnerability, project: pipeline.project) }
  let_it_be(:vulnerability_2) { create(:vulnerability, project: pipeline.project) }

  describe '#execute' do
    let(:ids_1) { [vulnerability_1.id] }
    let(:ids_2) { [] }

    subject(:ingest_reports) { service_object.execute }

    before do
      allow(Security::Ingestion::IngestReportService).to receive(:execute).and_return(ids_1, ids_2)
      allow(Security::Ingestion::MarkAsResolvedService).to receive(:execute)
      allow(Security::Ingestion::ScheduleMarkDroppedAsResolvedService).to receive(:execute)
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
    end

    it 'calls MarkAsResolvedService with the recently ingested vulnerability IDs' do
      ingest_reports

      expect(Security::Ingestion::MarkAsResolvedService).to have_received(:execute).with(project, ids_1)
    end

    it 'calls ScheduleMarkDroppedAsResolvedService with primary identifier IDs' do
      artifact = create(:ci_job_artifact, :sast_semgrep_for_gosec, job: build)

      ingest_reports

      expect(
        Security::Ingestion::ScheduleMarkDroppedAsResolvedService
      ).to have_received(:execute).with(project.id, 'sast', artifact.security_report.primary_identifiers)
    end

    describe 'scheduling the AutoFix background job' do
      let(:auto_fix_dependency_scanning?) { false }

      before do
        allow(Security::AutoFixWorker).to receive(:perform_async)
        allow(project.security_setting).to receive(:auto_fix_enabled?).and_return(auto_fix_enabled?)
        project.security_setting.update!(auto_fix_container_scanning: false, auto_fix_dependency_scanning: auto_fix_dependency_scanning?)

        ingest_reports
      end

      context 'when the auto_fix is not enabled for the project' do
        let(:auto_fix_enabled?) { false }

        context 'when the pipeline does not have any auto fix enabled report type' do
          it 'does not schedule the background job' do
            expect(Security::AutoFixWorker).not_to have_received(:perform_async)
          end
        end

        context 'when the pipeline has an auto fix enabled report type' do
          let(:auto_fix_dependency_scanning?) { true }

          it 'does not schedule the background job' do
            expect(Security::AutoFixWorker).not_to have_received(:perform_async)
          end
        end
      end

      context 'when the auto_fix is enabled for the project' do
        let(:auto_fix_enabled?) { true }

        context 'when the pipeline does not have any auto fix enabled report type' do
          it 'does not schedule the background job' do
            expect(Security::AutoFixWorker).not_to have_received(:perform_async)
          end
        end

        context 'when the pipeline has an auto fix enabled report type' do
          let(:auto_fix_dependency_scanning?) { true }

          it 'does not schedule the background job' do
            expect(Security::AutoFixWorker).to have_received(:perform_async)
          end
        end
      end
    end
  end
end
