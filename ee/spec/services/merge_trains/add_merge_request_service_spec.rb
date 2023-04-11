# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeTrains::AddMergeRequestService, feature_category: :continuous_integration do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :repository, merge_pipelines_enabled: true, merge_trains_enabled: true) }
  let_it_be(:guest) { create(:user) }
  let_it_be(:developer) { create(:user) }
  let_it_be(:maintainer) { create(:user) }
  let(:user) { maintainer }
  let(:merge_request) do
    create(:merge_request,
      source_project: project, source_branch: 'feature',
      target_project: project, target_branch: 'master',
      merge_status: 'unchecked')
  end

  let(:service) { described_class.new(merge_request, user, params) }
  let(:pipeline_status) { :success }

  before do
    allow(AutoMergeProcessWorker).to receive(:perform_async)

    stub_feature_flags(disable_merge_trains: false)
    stub_licensed_features(merge_trains: true, merge_pipelines: true)

    create(:ci_pipeline, pipeline_status, ref: merge_request.source_branch,
      sha: merge_request.diff_head_sha,
      project: merge_request.source_project)

    merge_request.update_head_pipeline
  end

  before_all do
    project.add_guest(guest)
    project.add_developer(developer)
    project.add_maintainer(maintainer)
  end

  shared_examples 'succeeds to add to merge train' do
    it 'returns success' do
      is_expected.to be_success
    end

    it 'succeeds to add to merge train' do
      subject

      merge_request.reload

      expect(merge_request.merge_train_car).to be_present
      expect(merge_request.merge_train_car.user).to eq(user)
    end
  end

  shared_examples 'fails to add to merge train' do
    it 'returns error' do
      is_expected.to be_error
    end

    it 'does not add to merge train' do
      subject

      merge_request.reload

      expect(merge_request.merge_train_car).not_to be_present
    end
  end

  describe '#execute' do
    subject { service.execute }

    let(:params) { {} }

    context 'when user is guest' do
      let(:user) { guest }

      it_behaves_like 'fails to add to merge train'
    end

    context 'when user is developer' do
      let(:user) { developer }

      it_behaves_like 'succeeds to add to merge train'
    end

    context 'when user is maintainer' do
      let(:user) { maintainer }

      it_behaves_like 'succeeds to add to merge train'
    end

    context 'when pipeline succeeds is true' do
      let(:params) { { when_pipeline_succeeds: true } }

      context 'when pipeline is completed' do
        let(:pipeline_status) { :success }

        it_behaves_like 'fails to add to merge train'
      end

      context 'when pipeline is not completed' do
        let(:pipeline_status) { :running }

        it 'returns success' do
          is_expected.to be_success
        end

        it 'waits to add to merge train' do
          subject

          merge_request.reload

          expect(merge_request.merge_train_car).not_to be_present
        end
      end
    end

    context 'when pipeline succeeds is false' do
      let(:params) { { when_pipeline_succeeds: false } }

      context 'when pipeline is completed' do
        let(:pipeline_status) { :success }

        it_behaves_like 'succeeds to add to merge train'
      end

      context 'when pipeline is not completed' do
        let(:pipeline_status) { :running }

        it_behaves_like 'fails to add to merge train'
      end
    end

    context 'when squash is true' do
      let(:params) { { squash: true } }

      it_behaves_like 'succeeds to add to merge train'

      it 'sets the squash merge request parameter' do
        subject

        merge_request.reload

        expect(merge_request.squash).to be_truthy
      end
    end

    context 'when squash is false' do
      let(:params) { { squash: false } }

      it_behaves_like 'succeeds to add to merge train'

      it 'sets the squash merge request parameter' do
        subject

        merge_request.reload

        expect(merge_request.squash).to be_falsey
      end
    end

    context 'when merge trains are disabled' do
      before do
        project.update!(merge_trains_enabled: false)
      end

      it_behaves_like 'fails to add to merge train'
    end
  end
end
