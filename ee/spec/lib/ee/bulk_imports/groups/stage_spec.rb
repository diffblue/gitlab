# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage do
  let(:entity) { create(:bulk_import_entity) }
  let(:expected_pipelines) do
    [
      { stage: 1, pipeline: BulkImports::Groups::Pipelines::IterationsPipeline, maximum_source_version: '15.3.0' },
      {
        stage: 1,
        pipeline: BulkImports::Groups::Pipelines::IterationsCadencesPipeline,
        minimum_source_version: '15.4.0'
      },
      { stage: 2, pipeline: BulkImports::Groups::Pipelines::EpicsPipeline },
      { stage: 2, pipeline: BulkImports::Common::Pipelines::WikiPipeline }
    ]
  end

  subject(:stage) { described_class.new(entity) }

  describe '#pipelines' do
    context 'when source is enterprise' do
      before do
        entity.bulk_import.update!(source_enterprise: true)
      end

      it 'includes EE pipelines' do
        expect(subject.pipelines).to include(*expected_pipelines)
      end

      it 'overrides the CE stage value for the EntityFinisher Pipeline' do
        expect(subject.pipelines.last).to eq({ stage: 4, pipeline: BulkImports::Common::Pipelines::EntityFinisher })
      end
    end

    context 'when source is not enterprise' do
      it 'does not include EE pipelines' do
        expect(subject.pipelines).not_to include(*expected_pipelines)
      end

      it 'does not override the CE stage value for the EntityFinisher Pipeline' do
        expect(subject.pipelines.last).to eq({ stage: 3, pipeline: BulkImports::Common::Pipelines::EntityFinisher })
      end
    end
  end
end
