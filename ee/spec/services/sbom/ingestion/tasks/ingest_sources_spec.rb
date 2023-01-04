# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::Tasks::IngestSources, feature_category: :dependency_management do
  describe '#execute' do
    let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }

    let(:report_source) { create(:ci_reports_sbom_source) }
    let(:occurrence_maps) { create_list(:sbom_occurrence_map, 4, report_source: report_source) }

    subject(:ingest_sources) { described_class.execute(pipeline, occurrence_maps) }

    it 'is idempotent' do
      expect { ingest_sources }.to change(Sbom::Source, :count).by(1)
      expect { ingest_sources }.not_to change(Sbom::Source, :count)
    end

    it 'sets source_id for all maps' do
      ingest_sources

      source_ids = occurrence_maps.map(&:source_id)
      source_id = source_ids.first
      expect(source_ids).to all(be_present)
      expect(source_ids).to all(eq(source_id))
    end

    context 'when source already exists' do
      let!(:existing_source) do
        create(:sbom_source, **occurrence_maps.first.to_h.slice(:source_type, :source))
      end

      it 'does not create a new record for the existing source' do
        expect { ingest_sources }.to change(Sbom::Source, :count).by(0)
      end

      it 'sets the source_id for all maps' do
        expected_source_ids = Array.new(3) { an_instance_of(Integer) }.unshift(existing_source.id)

        expect { ingest_sources }.to change { occurrence_maps.map(&:source_id) }
          .from(Array.new(4)).to(expected_source_ids)
      end
    end

    context 'when source is not present' do
      let(:occurrence_maps) { [create(:sbom_occurrence_map, report_source: nil)] }

      it 'performs no-op' do
        expect { ingest_sources }.to not_change { Sbom::Source.count }
          .and not_change { occurrence_maps.map(&:source_id) }
      end
    end

    context 'when occurrence_maps is empty' do
      let(:occurrence_maps) { [] }

      specify { expect { ingest_sources }.not_to raise_error }
    end
  end
end
