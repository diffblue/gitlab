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

    describe 'attributes' do
      let(:occurrence_maps) { [occurrence_map] }
      let(:occurrence_map) { create(:sbom_occurrence_map, :for_occurrence_ingestion) }
      let(:ingested_occurrence) { Sbom::Occurrence.last }

      before do
        licenses = ["MIT", "Apache-2.0"]
        occurrence_maps.map(&:report_component).each do |component|
          create(:pm_package, name: component.name, purl_type: component.purl&.type, default_license_names: licenses)
        end
      end

      it 'sets the correct attributes for the occurrence' do
        ingest_occurrences

        expect(ingested_occurrence.attributes).to include(
          'project_id' => pipeline.project.id,
          'pipeline_id' => pipeline.id,
          'component_id' => occurrence_map.component_id,
          'component_version_id' => occurrence_map.component_version_id,
          'source_id' => occurrence_map.source_id,
          'commit_sha' => pipeline.sha,
          'package_manager' => occurrence_map.packager,
          'input_file_path' => occurrence_map.input_file_path,
          'licenses' => [
            {
              'spdx_identifier' => 'Apache-2.0',
              'name' => 'Apache 2.0 License',
              'url' => 'https://spdx.org/licenses/Apache-2.0.html'
            },
            {
              'spdx_identifier' => 'MIT',
              'name' => 'MIT',
              'url' => 'https://spdx.org/licenses/MIT.html'
            }
          ],
          'component_name' => occurrence_map.name
        )
      end

      context 'when `ingest_sbom_licenses` is disabled' do
        before do
          stub_feature_flags(ingest_sbom_licenses: false)
        end

        it 'does not apply licenses' do
          ingest_occurrences

          expect(ingested_occurrence.licenses).to be_empty
        end
      end
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

      it 'does not include licenses' do
        ingest_occurrences

        expect(Sbom::Occurrence.pluck(:licenses)).to all(be_empty)
      end
    end

    context 'when there is no purl' do
      let(:component) { create(:ci_reports_sbom_component, purl: nil) }
      let(:occurrence_map) { create(:sbom_occurrence_map, :for_occurrence_ingestion, report_component: component) }
      let(:occurrence_maps) { [occurrence_map] }

      it 'skips licenses for components without a purl' do
        expect { ingest_occurrences }.to change(Sbom::Occurrence, :count).by(1)

        expect(Sbom::Occurrence.pluck(:licenses)).to all(be_empty)
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
