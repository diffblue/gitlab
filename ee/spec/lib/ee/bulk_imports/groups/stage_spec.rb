# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage do
  subject do
    entity = build(:bulk_import_entity)

    described_class.new(entity)
  end

  describe '#pipelines' do
    it 'includes EE pipelines' do
      expect(subject.pipelines).to include(
        { stage: 1, pipeline: BulkImports::Groups::Pipelines::IterationsPipeline, maximum_source_version: '15.3.0' },
        {
          stage: 1,
          pipeline: BulkImports::Groups::Pipelines::IterationsCadencesPipeline,
          minimum_source_version: '15.4.0'
        },
        { stage: 2, pipeline: BulkImports::Groups::Pipelines::EpicsPipeline },
        { stage: 2, pipeline: BulkImports::Common::Pipelines::WikiPipeline }
      )
    end

    it 'overrides the CE stage value for the EntityFinisher Pipeline' do
      expect(subject.pipelines.last).to eq({ stage: 4, pipeline: BulkImports::Common::Pipelines::EntityFinisher })
    end
  end
end
