# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::OccurrenceMapCollection, feature_category: :dependency_management do
  let_it_be(:num_components) { 5 }
  let_it_be(:sbom_report) { create(:ci_reports_sbom_report, num_components: num_components) }
  let_it_be(:expected_output) { Array.new(num_components) { Sbom::Ingestion::OccurrenceMap } }

  subject(:occurrence_map_collection) { described_class.new(sbom_report) }

  shared_examples '#each' do
    it 'yields for every component when given a block' do
      expect { |b| occurrence_map_collection.each(&b) }.to yield_successive_args(*expected_output)
    end

    context 'when not given a block' do
      let(:enumerator) { occurrence_map_collection.each }

      it 'creates an occurrence map for each occurrence' do
        expect(enumerator.to_a).to match_array(expected_output)
      end
    end
  end

  describe '#each' do
    it_behaves_like '#each'

    context 'when report source is nil' do
      let_it_be(:sbom_report) { create(:ci_reports_sbom_report, source: nil, num_components: num_components) }

      it_behaves_like '#each'
    end
  end
end
