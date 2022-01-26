# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BulkImports::Projects::Stage do
  let(:pipelines) do
    [
      [0, BulkImports::Projects::Pipelines::ProjectPipeline],
      [1, BulkImports::Projects::Pipelines::RepositoryPipeline],
      [1, BulkImports::Projects::Pipelines::ProjectAttributesPipeline],
      [1, BulkImports::Common::Pipelines::MembersPipeline],
      [2, BulkImports::Common::Pipelines::LabelsPipeline],
      [2, BulkImports::Common::Pipelines::MilestonesPipeline],
      [2, BulkImports::Common::Pipelines::BadgesPipeline],
      [3, BulkImports::Projects::Pipelines::IssuesPipeline],
      [3, BulkImports::Projects::Pipelines::SnippetsPipeline],
      [4, BulkImports::Projects::Pipelines::SnippetsRepositoryPipeline],
      [4, BulkImports::Common::Pipelines::BoardsPipeline],
      [4, BulkImports::Projects::Pipelines::MergeRequestsPipeline],
      [4, BulkImports::Projects::Pipelines::ExternalPullRequestsPipeline],
      [4, BulkImports::Projects::Pipelines::PushRulePipeline],
      [4, BulkImports::Projects::Pipelines::ProtectedBranchesPipeline],
      [4, BulkImports::Projects::Pipelines::CiPipelinesPipeline],
      [4, BulkImports::Projects::Pipelines::ProjectFeaturePipeline],
      [4, BulkImports::Projects::Pipelines::ContainerExpirationPolicyPipeline],
      [4, BulkImports::Projects::Pipelines::ServiceDeskSettingPipeline],
      [5, BulkImports::Common::Pipelines::WikiPipeline],
      [5, BulkImports::Common::Pipelines::UploadsPipeline],
      [5, BulkImports::Common::Pipelines::LfsObjectsPipeline],
      [5, BulkImports::Projects::Pipelines::AutoDevopsPipeline],
      [5, BulkImports::Projects::Pipelines::PipelineSchedulesPipeline],
      [6, BulkImports::Common::Pipelines::EntityFinisher]
    ]
  end

  subject do
    bulk_import = build(:bulk_import)

    described_class.new(bulk_import)
  end

  describe '#pipelines' do
    it 'list all the pipelines with their stage number, ordered by stage' do
      expect(subject.pipelines).to contain_exactly(*pipelines)
    end
  end
end
