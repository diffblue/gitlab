# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestPollWidgetEntity do
  include ProjectForksHelper

  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create :project, :repository }
  let_it_be(:merge_request, reload: true) { create(:merge_request, source_project: project, target_project: project) }

  let(:request) { double('request', current_user: user) }

  before do
    stub_feature_flags(disable_merge_trains: false)
    project.add_developer(user)
  end

  subject(:entity) do
    described_class.new(merge_request, current_user: user, request: request)
  end

  describe 'Merge Trains' do
    let!(:merge_train) { create(:merge_train_car, merge_request: merge_request) }

    before do
      stub_licensed_features(merge_pipelines: true, merge_trains: true)
      project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    end

    it 'has merge train entity' do
      expect(subject.as_json).to include(:merge_trains_count)
      expect(subject.as_json).to include(:merge_train_index)
    end

    context 'when the merge train feature is disabled' do
      before do
        stub_feature_flags(disable_merge_trains: true)
      end

      it 'does not have merge trains count' do
        expect(subject.as_json).not_to include(:merge_trains_count)
      end
    end

    context 'when the merge request is not on a merge train' do
      let!(:merge_train) {}

      it 'does not have merge train index' do
        expect(subject.as_json).not_to include(:merge_train_index)
      end
    end
  end
end
