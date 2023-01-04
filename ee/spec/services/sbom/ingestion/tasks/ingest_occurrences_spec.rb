# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::Tasks::IngestOccurrences, feature_category: :dependency_management do
  describe '#execute' do
    let_it_be(:pipeline) { build(:ci_pipeline) }

    let(:occurrence_maps) { create_list(:sbom_occurrence_map, 4, :for_occurrence_ingestion) }

    subject(:ingest_occurrences) { described_class.execute(pipeline, occurrence_maps) }

    it_behaves_like 'bulk insertable task'

    it 'is idempotent' do
      expect { ingest_occurrences }.to change(Sbom::Occurrence, :count).by(4)
      expect { ingest_occurrences }.not_to change(Sbom::Occurrence, :count)
    end

    context 'when there is an existing occurrence' do
      let!(:existing_occurrence) do
        attributes = occurrence_maps.first.to_h.slice(
          :component_id,
          :component_version_id,
          :source_id
        )

        create(:sbom_occurrence, pipeline: pipeline, **attributes)
      end

      it 'does not create a new record for the existing version' do
        expect { ingest_occurrences }.to change(Sbom::Occurrence, :count).by(3)
        expect(occurrence_maps).to all(have_attributes(occurrence_id: Integer))
      end
    end

    context 'when there is no component version' do
      let(:occurrence_maps) { create_list(:sbom_occurrence_map, 4, :for_occurrence_ingestion, component_version: nil) }

      it 'inserts records without the version' do
        expect { ingest_occurrences }.to change(Sbom::Occurrence, :count).by(4)
        expect(occurrence_maps).to all(have_attributes(occurrence_id: Integer))
      end
    end

    context 'when there are two duplicate occurrences' do
      let(:occurrence_maps) do
        map1 = create(:sbom_occurrence_map, :for_occurrence_ingestion)
        map2 = create(:sbom_occurrence_map)
        map2.component_id = map1.component_id
        map2.component_version_id = map1.component_version_id
        map2.source_id = map1.source_id

        [map1, map2]
      end

      it 'discards duplicates' do
        expect { ingest_occurrences }.to change { ::Sbom::Occurrence.count }.by(1)
        expect(occurrence_maps.size).to eq(1)
        expect(occurrence_maps).to all(have_attributes(occurrence_id: Integer))
      end
    end
  end
end
