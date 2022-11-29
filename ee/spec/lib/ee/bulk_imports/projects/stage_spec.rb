# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Stage do
  let(:entity) { create(:bulk_import_entity) }
  let(:expected_pipelines) do
    [
      { stage: 4, pipeline: BulkImports::Projects::Pipelines::PushRulePipeline }
    ]
  end

  subject(:stage) { described_class.new(entity) }

  describe '#pipelines' do
    context 'when source is enterprise' do
      it 'includes EE pipelines' do
        entity.bulk_import.update!(source_enterprise: true)

        expect(subject.pipelines).to include(*expected_pipelines)
      end
    end

    context 'when source is not enterprise' do
      it 'does not include EE pipelines' do
        expect(subject.pipelines).not_to include(*expected_pipelines)
      end
    end
  end
end
