# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::IngestReportSliceService, feature_category: :dependency_management do
  let_it_be(:num_occurrences) { 10 }
  let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }
  let_it_be(:occurrence_maps) { create_list(:sbom_occurrence_map, num_occurrences) }

  let(:sequencer) { ::Ingestion::Sequencer.new }

  subject(:execute) { described_class.execute(pipeline, occurrence_maps) }

  describe '#execute' do
    before do
      allow(::Sbom::Ingestion::Tasks::IngestOccurrences).to receive(:execute).and_wrap_original do |_, _, maps|
        maps.each { |map| map.occurrence_id = sequencer.next }
      end
    end

    it 'executes ingestion tasks in order' do
      tasks = [
        ::Sbom::Ingestion::Tasks::IngestComponents,
        ::Sbom::Ingestion::Tasks::IngestComponentVersions,
        ::Sbom::Ingestion::Tasks::IngestSources,
        ::Sbom::Ingestion::Tasks::IngestOccurrences
      ]

      expect(tasks).to all(receive(:execute).with(pipeline, occurrence_maps).ordered)
      expect(execute).to match_array(sequencer.range)
    end
  end
end
