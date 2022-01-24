# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Groups::Stage do
  let(:pipelines) do
    [
      [0, BulkImports::Groups::Pipelines::GroupPipeline],
      [1, BulkImports::Groups::Pipelines::SubgroupEntitiesPipeline],
      [1, BulkImports::Common::Pipelines::MembersPipeline],
      [1, BulkImports::Common::Pipelines::LabelsPipeline],
      [1, BulkImports::Common::Pipelines::MilestonesPipeline],
      [1, BulkImports::Common::Pipelines::BadgesPipeline],
      [1, BulkImports::Groups::Pipelines::IterationsPipeline],
      [1, BulkImports::Groups::Pipelines::ProjectEntitiesPipeline],
      [2, BulkImports::Common::Pipelines::BoardsPipeline],
      [2, BulkImports::Groups::Pipelines::EpicsPipeline],
      [2, BulkImports::Common::Pipelines::WikiPipeline],
      [2, BulkImports::Common::Pipelines::UploadsPipeline],
      [4, BulkImports::Common::Pipelines::EntityFinisher]
    ]
  end

  subject do
    bulk_import = build(:bulk_import)

    described_class.new(bulk_import)
  end

  describe '#each' do
    it 'iterates over all pipelines with the stage number' do
      expect(subject.pipelines).to match_array(pipelines)
    end
  end
end
