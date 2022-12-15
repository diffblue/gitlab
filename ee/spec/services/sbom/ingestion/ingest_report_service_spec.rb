# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::IngestReportService, feature_category: :dependency_management do
  let_it_be(:num_components) { 283 }
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:sbom_report) { create(:ci_reports_sbom_report, num_components: num_components) }

  subject(:execute) { described_class.execute(pipeline, sbom_report) }

  describe '#execute' do
    it 'executes IngestReportSliceService in batches' do
      full_batches, remainder = num_components.divmod(described_class::BATCH_SIZE)
      expect(::Sbom::Ingestion::IngestReportSliceService).to receive(:execute)
        .with(pipeline, an_object_having_attributes(size: described_class::BATCH_SIZE)).exactly(full_batches).times
      expect(::Sbom::Ingestion::IngestReportSliceService).to receive(:execute)
        .with(pipeline, an_object_having_attributes(size: remainder)).once

      execute
    end
  end
end
