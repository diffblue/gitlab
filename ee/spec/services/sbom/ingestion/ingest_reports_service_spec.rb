# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::IngestReportsService, feature_category: :dependency_management do
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }
  let_it_be(:reports) { create_list(:ci_reports_sbom_report, 4) }

  let(:sequencer) { ::Ingestion::Sequencer.new }
  let(:wrapper) { instance_double('Gitlab::Ci::Reports::Sbom::Reports') }

  subject(:execute) { described_class.execute(pipeline) }

  before do
    allow(wrapper).to receive(:reports).and_return(reports)
    allow(pipeline).to receive(:sbom_reports).and_return(wrapper)
  end

  describe '#execute' do
    before do
      allow(::Sbom::Ingestion::DeleteNotPresentOccurrencesService).to receive(:execute)
      allow(::Sbom::Ingestion::IngestReportService).to receive(:execute)
        .and_wrap_original do |_, _, report|
          report.components.map { sequencer.next }
        end
    end

    it 'executes IngestReportService for each report' do
      reports.each do |report|
        expect(::Sbom::Ingestion::IngestReportService).to receive(:execute).with(pipeline, report)
      end

      execute

      expect(::Sbom::Ingestion::DeleteNotPresentOccurrencesService).to have_received(:execute)
        .with(pipeline, sequencer.range)
    end

    context 'when a report is invalid' do
      let_it_be(:invalid_report) { create(:ci_reports_sbom_report, :invalid) }
      let_it_be(:valid_reports) { create_list(:ci_reports_sbom_report, 4) }
      let_it_be(:reports) { [invalid_report] + valid_reports }

      it 'does not process the invalid report' do
        expect(::Sbom::Ingestion::IngestReportService).not_to receive(:execute).with(pipeline, invalid_report)

        valid_reports.each do |report|
          expect(::Sbom::Ingestion::IngestReportService).to receive(:execute).with(pipeline, report)
        end

        execute

        expect(::Sbom::Ingestion::DeleteNotPresentOccurrencesService).to have_received(:execute)
          .with(pipeline, sequencer.range)
      end
    end
  end
end
