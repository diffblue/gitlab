# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Stage do
  subject do
    entity = build(:bulk_import_entity)

    described_class.new(entity)
  end

  describe '#pipelines' do
    it 'includes EE pipelines' do
      expect(subject.pipelines).to include({ stage: 4, pipeline: BulkImports::Projects::Pipelines::PushRulePipeline })
    end
  end
end
