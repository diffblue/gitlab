# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeTrains::Train, feature_category: :merge_trains do
  let_it_be(:project) { create(:project, :repository) }

  let(:train) { described_class.new(target_project, target_branch) }

  describe '#all_cars' do
    let(:target_project) { merge_request.target_project }
    let(:target_branch)  { merge_request.target_branch }
    let!(:merge_request) { create_merge_request_on_train }

    subject { train.all_cars }

    it 'returns the merge request car' do
      is_expected.to eq([merge_request.merge_train_car])
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns both cars in order of creation' do
        is_expected.to eq([merge_request.merge_train_car, merge_request_2.merge_train_car])
      end
    end

    context 'when the merge request has already been merged' do
      let!(:merge_request) { create_merge_request_on_train(status: :merged) }

      it { is_expected.to be_empty }
    end

    context 'when the merge request is not on merge train' do
      let(:merge_request) { create(:merge_request) }

      it { is_expected.to be_empty }
    end
  end

  describe '#first_car' do
    subject { train.first_car }

    let(:target_project) { merge_request.target_project }
    let(:target_branch) { merge_request.target_branch }
    let!(:merge_request) { create_merge_request_on_train }

    it 'returns the merge request' do
      is_expected.to eq(merge_request.merge_train_car)
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the merge request' do
        is_expected.to eq(merge_request.merge_train_car)
      end
    end

    context 'when the merge request has already been merged' do
      let!(:merge_request) { create_merge_request_on_train(status: :merged) }

      it { is_expected.to be_nil }
    end

    context 'when the merge request is not on merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'returns empty array' do
        is_expected.to be_nil
      end
    end
  end

  describe '#sha_exists_in_history?' do
    subject { train.sha_exists_in_history?(target_sha, limit: limit) }

    let(:target_project) { project }
    let(:target_branch) { 'master' }
    let(:target_sha) { '' }
    let(:limit) { 20 }

    context 'when there is a merge request on train' do
      let!(:merge_request_1) { create_merge_request_on_train }
      let(:merge_commit_sha_1) { OpenSSL::Digest.hexdigest('SHA256', 'test-1') }
      let(:target_sha) { merge_commit_sha_1 }

      context 'when the merge request has already been merging' do
        let!(:merge_request_1) { create_merge_request_on_train(status: :merging) }

        before do
          merge_request_1.update_column(:in_progress_merge_commit_sha, merge_commit_sha_1)
        end

        it { is_expected.to eq(true) }
      end

      context 'when the merge request has already been merged' do
        let!(:merge_request_1) { create_merge_request_on_train(status: :merged) }

        before do
          merge_request_1.update_column(:merge_commit_sha, merge_commit_sha_1)
        end

        it { is_expected.to eq(true) }
      end

      context 'when there is another merge request on train and it has been merged' do
        let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome', status: :merged) }
        let(:merge_commit_sha_2) { OpenSSL::Digest.hexdigest('SHA256', 'test-2') }
        let(:target_sha) { merge_commit_sha_2 }

        before do
          merge_request_2.update_column(:merge_commit_sha, merge_commit_sha_2)
        end

        it { is_expected.to eq(true) }

        context 'when limit is 1' do
          let(:limit) { 1 }
          let(:target_sha) { merge_commit_sha_1 }

          it { is_expected.to eq(false) }
        end
      end

      context 'when the merge request has not been merged yet' do
        it { is_expected.to eq(false) }
      end
    end

    context 'when there are no merge requests on train' do
      it { is_expected.to eq(false) }
    end
  end

  describe '#car_count' do
    subject { train.car_count }

    let(:target_project) { merge_request.target_project }
    let(:target_branch) { merge_request.target_branch }
    let!(:merge_request) { create_merge_request_on_train }

    it 'returns the merge request' do
      is_expected.to eq(1)
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the merge request' do
        is_expected.to eq(2)
      end
    end

    context 'when the merge request has already been merged' do
      let!(:merge_request) { create_merge_request_on_train(status: :merged) }

      it 'returns zero' do
        is_expected.to be(0)
      end
    end

    context 'when the merge request is not on merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'returns empty array' do
        is_expected.to be(0)
      end
    end
  end

  def create_merge_request_on_train(
    target_project: project, target_branch: 'master', source_project: project,
    source_branch: 'feature', status: :idle)
    create(:merge_request,
      :on_train,
      target_branch: target_branch,
      target_project: target_project,
      source_branch: source_branch,
      source_project: source_project,
      status: MergeTrains::Car.state_machines[:status].states[status].value)
  end
end
