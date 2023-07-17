# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPollWidgetEntity, feature_category: :merge_trains do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create :project, :repository }
  let(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:request) { double('request', current_user: user) }

  before do
    stub_feature_flags(disable_merge_trains: false)
    project.add_developer(user)
  end

  subject(:entity) do
    described_class.new(merge_request, current_user: user, request: request).as_json
  end

  describe 'Merge Trains' do
    let!(:merge_train) { create(:merge_train_car, merge_request: merge_request) }

    before do
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
      project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    end

    it 'has merge train entity' do
      expect(entity).to include(:merge_trains_count)
      expect(entity).to include(:merge_train_index)
    end

    context 'when the merge train feature is disabled' do
      before do
        stub_feature_flags(disable_merge_trains: true)
      end

      it 'does not have merge trains count' do
        expect(entity).not_to include(:merge_trains_count)
      end
    end

    context 'when the merge request is not on a merge train' do
      let!(:merge_train) {}

      it 'does not have merge train index' do
        expect(entity).not_to include(:merge_train_index)
      end
    end
  end

  describe 'auto merge' do
    context 'when head pipeline is running' do
      before do
        create(:ci_pipeline, :running,
          project: project, ref: merge_request.source_branch, sha: merge_request.diff_head_sha)
        merge_request.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(entity[:available_auto_merge_strategies]).to(
          eq(%w[merge_when_checks_pass merge_when_pipeline_succeeds])
        )
      end
    end

    context 'when head pipeline is finished and approvals are pending' do
      before do
        create(:approval_merge_request_rule, merge_request: merge_request, approvals_required: 1, users: [user])
        create(:ci_pipeline, :success,
          project: project, ref: merge_request.source_branch, sha: merge_request.diff_head_sha)
        merge_request.update_head_pipeline
      end

      it 'returns available auto merge strategies' do
        expect(entity[:available_auto_merge_strategies]).to(
          eq(%w[merge_when_checks_pass])
        )
      end
    end
  end
end
