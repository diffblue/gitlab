# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sbom::Ingestion::OccurrenceMap do
  let_it_be(:report_component) { create(:ci_reports_sbom_component) }
  let_it_be(:report_source) { create(:ci_reports_sbom_source) }

  subject(:occurrence_map) { described_class.new(report_component, report_source) }

  let(:base_data) do
    {
      component_id: nil,
      component_type: report_component.component_type,
      component_version_id: nil,
      name: report_component.name,
      version: report_component.version,
      source: report_source.data,
      source_id: nil,
      source_type: report_source.source_type
    }
  end

  describe '#to_h' do
    it 'returns a hash with base data without ids assigned' do
      expect(occurrence_map.to_h).to eq(base_data)
    end

    context 'when ids are assigned' do
      let(:ids) do
        {
          component_id: 1,
          component_version_id: 2,
          source_id: 3
        }
      end

      before do
        occurrence_map.component_id = ids[:component_id]
        occurrence_map.component_version_id = ids[:component_version_id]
        occurrence_map.source_id = ids[:source_id]
      end

      it 'returns a hash with ids and base data' do
        expect(occurrence_map.to_h).to eq(base_data.merge(ids))
      end
    end
  end

  describe '#version_present?' do
    it 'returns true when a version is present' do
      expect(occurrence_map.version_present?).to be(true)
    end

    context 'when version is empty' do
      let_it_be(:report_component) { create(:ci_reports_sbom_component, version: '') }

      specify { expect(occurrence_map.version_present?).to be(false) }
    end

    context 'when version is absent' do
      let_it_be(:report_component) { create(:ci_reports_sbom_component, version: nil) }

      it { expect(occurrence_map.version_present?).to be(false) }
    end
  end
end
