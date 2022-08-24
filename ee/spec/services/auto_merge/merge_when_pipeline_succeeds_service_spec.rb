# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::MergeWhenPipelineSucceedsService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:mr_merge_if_green_enabled) do
    create(:merge_request,
      merge_when_pipeline_succeeds: true,
      merge_user: user,
      source_branch: "master", target_branch: 'feature',
      source_project: project, target_project: project,
      state: "opened")
  end

  let(:pipeline) do
    create(:ci_pipeline, ref: mr_merge_if_green_enabled.source_branch, project: project)
  end

  let(:service) do
    described_class.new(project, user, commit_message: 'Awesome message')
  end

  before_all do
    project.add_maintainer(user)
  end

  before do
    allow(MergeWorker).to receive(:with_status).and_return(MergeWorker)
  end

  describe "#available_for?" do
    subject { service.available_for?(mr_merge_if_green_enabled) }

    let(:pipeline_status) { :running }

    before do
      create(:ci_pipeline, pipeline_status,
        ref: mr_merge_if_green_enabled.source_branch,
        sha: mr_merge_if_green_enabled.diff_head_sha,
        project: mr_merge_if_green_enabled.source_project)
      mr_merge_if_green_enabled.update_head_pipeline
    end

    context 'when there is an open MR dependency' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
        create(:merge_request_block, blocked_merge_request: mr_merge_if_green_enabled)
      end

      it { is_expected.to be_falsy }
    end
  end
end
