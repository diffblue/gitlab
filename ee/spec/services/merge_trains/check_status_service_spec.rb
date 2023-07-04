# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeTrains::CheckStatusService, feature_category: :merge_trains do
  let_it_be(:project) { create(:project, :repository, merge_pipelines_enabled: true, merge_trains_enabled: true) }
  let_it_be(:maintainer) { create(:user).tap { |u| project.add_maintainer(u) } }

  let(:service) { described_class.new(project, maintainer) }
  let(:previous_ref) { 'refs/heads/master' }

  before do
    stub_feature_flags(disable_merge_trains: false)
    stub_licensed_features(merge_pipelines: true, merge_trains: true)
  end

  describe '#execute' do
    subject { service.execute(target_project, target_branch, newrev) }

    let(:target_project) { project }
    let(:target_branch) { 'master' }
    let(:newrev) { Digest::SHA1.hexdigest 'test' }

    context 'when there is at least one merge request on the train' do
      let!(:merged_merge_request) do
        create(:merge_request, :on_train,
          train_creator: maintainer,
          source_branch: 'feature', source_project: project,
          target_branch: 'master', target_project: project,
          merge_status: 'unchecked', status: MergeTrains::Car.state_machines[:status].states[:merged].value)
      end

      let!(:active_merge_request) do
        create(:merge_request, :on_train,
          train_creator: maintainer,
          source_branch: 'improve/awesome', source_project: project,
          target_branch: 'master', target_project: project,
          merge_status: 'unchecked')
      end

      before do
        merged_merge_request.mark_as_merged!
        merged_merge_request.update_column(:merge_commit_sha, merge_commit_sha_1)
      end

      context 'when new revision is included in merge train history' do
        let!(:merge_commit_sha_1) { Digest::SHA1.hexdigest 'test' }

        it 'does not outdate the merge train pipeline' do
          expect_next_instance_of(MergeTrains::Train) do |train|
            expect(train)
              .to receive(:sha_exists_in_history?)
              .and_return(true)
              .and_call_original

            expect(train).not_to receive(:first_car)
          end

          expect_any_instance_of(MergeTrains::Car).not_to receive(:outdate_pipeline)

          subject
        end
      end

      context 'when new revision is not included in merge train history' do
        let!(:merge_commit_sha_1) { Digest::SHA1.hexdigest 'other' }
        let(:car_double) { instance_double(MergeTrains::Car) }

        it 'outdates the merge train pipeline' do
          expect_next_instance_of(MergeTrains::Train) do |train|
            expect(train)
              .to receive(:sha_exists_in_history?)
              .and_return(false)
              .and_call_original

            expect(train)
              .to receive(:first_car)
              .and_return(car_double)
          end

          expect(car_double).to receive(:outdate_pipeline)

          subject
        end
      end
    end

    context 'when there are no merge requests on train' do
      it 'does not raise error' do
        expect_next_instance_of(MergeTrains::Train) do |train|
          expect(train)
            .to receive(:sha_exists_in_history?)
            .and_return(false)
            .and_call_original
        end

        expect { subject }.not_to raise_error
      end
    end

    context 'when merge train is disabled on the project' do
      before do
        project.update!(merge_pipelines_enabled: false)
      end

      it 'returns immediately without loading any Trains to check the history of' do
        expect(MergeTrains::Train).not_to receive(:new)

        subject
      end
    end
  end
end
