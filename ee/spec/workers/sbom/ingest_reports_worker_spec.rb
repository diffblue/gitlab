# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::IngestReportsWorker, feature_category: :dependency_management do
  let_it_be(:pipeline) { create(:ee_ci_pipeline, :with_cyclonedx_report) }

  describe '#perform' do
    subject(:run_worker) { described_class.new.perform(pipeline.id) }

    before do
      allow(Sbom::Ingestion::IngestReportsService).to receive(:execute)
      allow_next_found_instance_of(Ci::Pipeline) do |record|
        allow(record).to receive(:can_ingest_sbom_reports?).and_return(can_ingest_sbom_reports)
      end
    end

    context 'when there is no pipeline with the given ID' do
      subject(:perform) { described_class.new.perform(non_existing_record_id) }

      it 'does not raise an error' do
        expect { perform }.not_to raise_error
      end
    end

    context 'when sbom reports can not be stored for the pipeline' do
      let(:can_ingest_sbom_reports) { false }

      it 'does not call `Sbom::Ingestion::IngestReportsService`' do
        run_worker

        expect(Sbom::Ingestion::IngestReportsService).not_to have_received(:execute)
      end
    end

    context 'when sbom reports can be stored for the pipeline' do
      let(:can_ingest_sbom_reports) { true }

      it 'calls `Sbom::Ingestion::IngestReportsService`' do
        run_worker

        expect(Sbom::Ingestion::IngestReportsService).to have_received(:execute)
      end
    end
  end
end
