# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::IngestReportSliceService, feature_category: :dependency_management do
  let_it_be(:pipeline) { create(:ci_pipeline) }
  let_it_be(:occurrence_maps) { create_list(:sbom_occurrence_map, 10) }

  subject(:execute) { described_class.execute(pipeline, occurrence_maps) }

  describe '#execute' do
    it 'executes ingestion tasks in order' do
      tasks = [
        ::Sbom::Ingestion::Tasks::IngestComponents,
        ::Sbom::Ingestion::Tasks::IngestComponentVersions,
        ::Sbom::Ingestion::Tasks::IngestSources,
        ::Sbom::Ingestion::Tasks::IngestOccurrences
      ]

      expect(tasks).to all(receive(:execute).with(pipeline, occurrence_maps).ordered)

      execute
    end
  end
end
