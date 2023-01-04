# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::Tasks::IngestComponents, feature_category: :dependency_management do
  describe '#execute' do
    let_it_be(:pipeline) { build_stubbed(:ci_pipeline) }

    let(:occurrence_maps) { create_list(:sbom_occurrence_map, 4) }
    let!(:existing_component) { create(:sbom_component, **occurrence_maps.first.to_h.slice(:component_type, :name)) }

    subject(:ingest_components) { described_class.execute(pipeline, occurrence_maps) }

    it_behaves_like 'bulk insertable task'

    it 'is idempotent' do
      expect { ingest_components }.to change(Sbom::Component, :count).by(3)
      expect { ingest_components }.not_to change(Sbom::Component, :count)
    end

    it 'sets the component_id' do
      expected_component_ids = Array.new(3) { an_instance_of(Integer) }.unshift(existing_component.id)

      expect { ingest_components }.to change { occurrence_maps.map(&:component_id) }
        .from(Array.new(4)).to(expected_component_ids)
    end

    context 'when there are duplicate components' do
      let(:components) do
        [
          create(
            :ci_reports_sbom_component,
            name: "golang.org/x/sys",
            version: "v0.0.0-20190422165155-953cdadca894",
            purl_type: "golang"
          ),
          create(
            :ci_reports_sbom_component,
            name: "golang.org/x/sys",
            version: "v0.0.0-20191026070338-33540a1f6037",
            purl_type: "golang"
          )
        ]
      end

      let(:occurrence_maps) { components.map { |component| create(:sbom_occurrence_map, report_component: component) } }

      it 'fills in component_id for both records' do
        ingest_components

        ids = occurrence_maps.map(&:component_id)

        expect(ids).to all(be_present)
        expect(ids.first).to eq(ids.last)
      end
    end

    context 'when components have the same name but different purl_types' do
      let(:components) do
        [
          create(
            :ci_reports_sbom_component,
            name: "pg",
            version: "v0.0.1",
            purl_type: "gem"
          ),
          create(
            :ci_reports_sbom_component,
            name: "pg",
            version: "v0.0.1",
            purl_type: "pypi"
          )
        ]
      end

      let(:occurrence_maps) { components.map { |component| create(:sbom_occurrence_map, report_component: component) } }

      it 'creates two distinct components' do
        expect { ingest_components }.to change(Sbom::Component, :count).by(2)
      end
    end

    context 'when there is a pypi component' do
      let(:report_component) do
        create(
          :ci_reports_sbom_component,
          name: 'Flask_SQLAlchemy',
          version: 'v0.0.1',
          purl_type: 'pypi'
        )
      end

      let(:occurrence_maps) { [create(:sbom_occurrence_map, report_component: report_component)] }

      it 'normalizes component name' do
        ingest_components

        component = Sbom::Component.find_by(purl_type: :pypi)

        expect(component).to have_attributes(
          name: 'flask-sqlalchemy',
          purl_type: 'pypi',
          component_type: 'library'
        )
      end
    end
  end
end
