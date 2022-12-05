# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::MergeRequests::Accept do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let(:context) do
    GraphQL::Query::Context.new(
      query: query_double(schema: GitlabSchema),
      values: { current_user: user },
      object: nil
    )
  end

  let(:project) { create(:project, :public, :repository) }

  subject(:mutation) { described_class.new(context: context, object: nil, field: nil) }

  def mutation_arguments(merge_request)
    {
      project_path: project.full_path,
      iid: merge_request.iid.to_s,
      sha: merge_request.diff_head_sha,
      squash: false
    }
  end

  describe '#resolve' do
    before do
      project.add_maintainer(user)
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
      stub_feature_flags(disable_merge_trains: false)
      project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    end

    it "can use the MERGE_TRAIN strategy" do
      enum = ::Types::MergeStrategyEnum.values['MERGE_TRAIN']
      merge_request = create(:merge_request, :with_test_reports,
                             source_project: project)

      args = mutation_arguments(merge_request).merge(
        auto_merge_strategy: enum.value
      )
      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(merge_request: be_auto_merge_enabled)
    end

    it "can use the ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS strategy" do
      enum = ::Types::MergeStrategyEnum.values['ADD_TO_MERGE_TRAIN_WHEN_PIPELINE_SUCCEEDS']
      merge_request = create(:merge_request, :with_head_pipeline,
                             source_project: project)

      args = mutation_arguments(merge_request).merge(
        auto_merge_strategy: enum.value
      )
      result = mutation.resolve(**args)

      expect(result).not_to include(merge_request: be_merged)
      expect(result).to include(merge_request: be_auto_merge_enabled)
    end
  end
end
