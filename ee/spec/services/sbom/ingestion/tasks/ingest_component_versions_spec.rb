# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::Tasks::IngestComponentVersions, feature_category: :dependency_management do
  describe '#execute' do
    let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }

    let(:occurrence_maps) { create_list(:sbom_occurrence_map, 4, :with_component) }

    subject(:ingest_component_versions) { described_class.execute(pipeline, occurrence_maps) }

    it_behaves_like 'bulk insertable task'

    it 'is idempotent' do
      expect { ingest_component_versions }.to change(Sbom::ComponentVersion, :count).by(4)
      expect { ingest_component_versions }.not_to change(Sbom::ComponentVersion, :count)
    end

    context 'when there is an existing version' do
      let!(:existing_version) do
        create(:sbom_component_version, **occurrence_maps.first.to_h.slice(:component_id, :version))
      end

      it 'does not create a new record for the existing version' do
        expect { ingest_component_versions }.to change(Sbom::ComponentVersion, :count).by(3)
      end

      it 'sets the component_id' do
        expected_component_ids = Array.new(3) { an_instance_of(Integer) }.unshift(existing_version.id)

        expect { ingest_component_versions }.to change { occurrence_maps.map(&:component_version_id) }
          .from(Array.new(4)).to(expected_component_ids)
      end
    end

    context 'when there is no version attribute' do
      let(:good_occurrence_map_1) { create(:sbom_occurrence_map, :with_component) }
      let(:good_occurrence_map_2) { create(:sbom_occurrence_map, :with_component) }
      let(:report_component) { create(:ci_reports_sbom_component, version: nil) }
      let(:nil_occurence_map) { create(:sbom_occurrence_map, :with_component, report_component: report_component) }
      let(:occurrence_maps) { [good_occurrence_map_1, nil_occurence_map, good_occurrence_map_2] }

      it 'skips creation for missing version' do
        expect { ingest_component_versions }.to change(Sbom::ComponentVersion, :count).by(2)
      end

      it 'does not set component_version_id when skipped' do
        expect { ingest_component_versions }.to change { occurrence_maps.map(&:component_version_id) }
          .from(Array.new(3)).to([an_instance_of(Integer), nil, an_instance_of(Integer)])
      end
    end

    context 'when occurrence maps contains two of the same component_version' do
      let_it_be(:component) { create(:sbom_component) }
      let_it_be(:report_component) { create(:ci_reports_sbom_component, version: 'v0.0.1') }

      let(:occurrence_maps) do
        create_list(:sbom_occurrence_map, 2, component: component, report_component: report_component)
      end

      it 'fills in both ids' do
        expect { ingest_component_versions }.to change { occurrence_maps.map(&:component_version_id) }
          .from(Array.new(2)).to([an_instance_of(Integer), an_instance_of(Integer)])
      end
    end
  end
end
