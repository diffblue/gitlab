# frozen_string_literal: true

require "spec_helper"

RSpec.describe MergeTrains::Car, feature_category: :merge_trains do
  include ProjectForksHelper

  let_it_be(:project) { create(:project, :repository) }

  before do
    allow(AutoMergeProcessWorker).to receive(:perform_async)
  end

  it { is_expected.to belong_to(:merge_request) }
  it { is_expected.to belong_to(:user) }
  it { is_expected.to belong_to(:pipeline) }

  shared_context 'with train cars in many states' do
    let_it_be(:idle_car) { create(:merge_train_car, :idle) }
    let_it_be(:stale_car) { create(:merge_train_car, :stale) }
    let_it_be(:fresh_car) { create(:merge_train_car, :fresh) }
    let_it_be(:merged_car) { create(:merge_train_car, :merged) }
    let_it_be(:merging_car) { create(:merge_train_car, :merging) }
  end

  describe '.active' do
    subject { described_class.active }

    include_context 'with train cars in many states'

    it 'returns only active merge trains' do
      is_expected.to contain_exactly(idle_car, stale_car, fresh_car)
    end
  end

  describe '.complete' do
    subject { described_class.complete }

    include_context 'with train cars in many states'

    it 'returns only merged merge trains' do
      is_expected.to contain_exactly(merged_car, merging_car)
    end
  end

  describe '.for_target' do
    subject { described_class.for_target(project_id, branch) }

    let!(:train_car_1) { create(:merge_train_car) }
    let!(:train_car_2) { create(:merge_train_car) }

    context "when target merge train 1's project" do
      let(:project_id) { train_car_1.target_project_id }
      let(:branch) { train_car_1.target_branch }

      it 'returns merge train 1 only' do
        is_expected.to eq([train_car_1])
      end
    end

    context "when target merge train 2's project" do
      let(:project_id) { train_car_2.target_project_id }
      let(:branch) { train_car_2.target_branch }

      it 'returns merge train 2 only' do
        is_expected.to eq([train_car_2])
      end
    end
  end

  describe '.by_id' do
    subject { described_class.by_id }

    let!(:train_car_1) { create(:merge_train_car, target_project: project, target_branch: 'master') }
    let!(:train_car_2) { create(:merge_train_car, target_project: project, target_branch: 'master') }

    it 'returns merge trains by id ASC' do
      is_expected.to eq([train_car_1, train_car_2])
    end
  end

  describe '.all_active_mrs_in_train' do
    subject { described_class.all_active_mrs_in_train(target_project_id, target_branch) }

    let(:target_project_id) { merge_request.target_project_id }
    let(:target_branch) { merge_request.target_branch }
    let!(:merge_request) { create_merge_request_on_train }

    it 'returns the merge request' do
      is_expected.to eq([merge_request])
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the merge requests' do
        is_expected.to eq([merge_request, merge_request_2])
      end
    end

    context 'when the merge request has already been merged' do
      let!(:merge_request) { create_merge_request_on_train(status: :merged) }

      it { is_expected.to be_empty }
    end

    context 'when the merge request is not on merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'returns empty array' do
        is_expected.to be_empty
      end
    end
  end

  describe '.first_car' do
    subject { described_class.first_car(target_project_id, target_branch) }

    let(:target_project_id) { merge_request.target_project_id }
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

  describe '.first_cars_in_trains' do
    let!(:first_on_master) { create_merge_request_on_train(target_branch: 'master', source_branch: 'feature-1') }
    let!(:second_on_master) { create_merge_request_on_train(target_branch: 'master', source_branch: 'feature-2') }

    let!(:first_on_stable) do
      create_merge_request_on_train(target_branch: 'stable', source_branch: 'feature-1-backport')
    end

    let!(:second_on_stable) do
      create_merge_request_on_train(target_branch: 'stable', source_branch: 'feature-2-backport')
    end

    subject { described_class.first_cars_in_trains(project) }

    it 'returns only first merge requests per merge train' do
      is_expected.to contain_exactly(first_on_master.merge_train_car, first_on_stable.merge_train_car)
    end

    context 'when first_on_master has already been merged' do
      let!(:first_on_master) do
        create_merge_request_on_train(target_branch: 'master', source_branch: 'feature-1', status: :merged)
      end

      it 'returns second on master as active MR' do
        is_expected.to contain_exactly(second_on_master.merge_train_car, first_on_stable.merge_train_car)
      end
    end
  end

  describe '.sha_exists_in_history?' do
    subject { described_class.sha_exists_in_history?(target_project_id, target_branch, target_sha, limit: limit) }

    let(:target_project_id) { project.id }
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

  describe '.total_count_in_train' do
    subject { described_class.total_count_in_train(merge_request) }

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

  describe '#all_next' do
    subject { car.all_next }

    let(:car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    it 'returns nil' do
      is_expected.to be_empty
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the next merge requests' do
        is_expected.to eq([merge_request_2.merge_train_car])
      end
    end
  end

  describe '#all_prev' do
    subject { train_car.all_prev }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when the merge request is at first on the train' do
      it 'returns nil' do
        is_expected.to be_empty
      end
    end

    context 'when the merge request is at last on the train' do
      let(:train_car) { merge_request_2.merge_train_car }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the previous merge requests' do
        is_expected.to eq([merge_request.merge_train_car])
      end

      context 'when the previous merge request has already been merged' do
        let!(:merge_request) { create_merge_request_on_train(status: :merged) }

        it 'returns empty array' do
          is_expected.to be_empty
        end
      end
    end
  end

  describe '#next' do
    subject { train_car.next }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when the merge request is at last on the train' do
      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when the other merge request is on the merge train' do
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the next merge request' do
        is_expected.to eq(merge_request_2.merge_train_car)
      end
    end
  end

  describe '#prev' do
    subject { train_car.prev }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when the merge request is at first on the train' do
      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    context 'when the merge request is at last on the train' do
      let(:train_car) { merge_request_2.merge_train_car }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it 'returns the next merge request' do
        is_expected.to eq(merge_request.merge_train_car)
      end
    end
  end

  describe '#previous_ref' do
    subject { train_car.previous_ref }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when merge request is first on train' do
      it 'returns the target branch' do
        is_expected.to eq(merge_request.target_branch_ref)
      end
    end

    context 'when merge request is not first on train' do
      let(:train_car) { merge_request_2.merge_train_car }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'feature-2') }

      it 'returns the ref of the previous merge request' do
        is_expected.to eq(merge_request.train_ref_path)
      end
    end
  end

  describe '#requires_new_pipeline?' do
    subject { train_car.requires_new_pipeline? }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when merge train has a pipeline associated' do
      before do
        train_car.update!(pipeline: create(:ci_pipeline, project: train_car.project))
      end

      it { is_expected.to be_falsey }

      context 'when merge train is stale' do
        before do
          train_car.update!(status: described_class.state_machines[:status].states[:stale].value)
        end

        it { is_expected.to be_truthy }
      end
    end

    context 'when merge train does not have a pipeline' do
      before do
        train_car.update!(pipeline: nil)
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#pipeline_not_succeeded?' do
    subject { train_car.pipeline_not_succeeded? }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when merge train does not have a pipeline' do
      it { is_expected.to be_falsey }
    end

    context 'when merge train has a pipeline' do
      let(:pipeline) { create(:ci_pipeline, project: train_car.project, status: status) }

      before do
        train_car.update!(pipeline: pipeline)
      end

      context 'when pipeline failed' do
        let(:status) { :failed }

        it { is_expected.to be_truthy }
      end

      context 'when pipeline succeeded' do
        let(:status) { :success }

        it { is_expected.to be_falsey }
      end

      context 'when pipeline is running' do
        let(:status) { :running }

        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#cancel_pipeline!' do
    subject { train_car.cancel_pipeline!(new_pipeline) }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }
    let!(:pipeline) { create(:ci_pipeline, :running, project: train_car.project) }
    let!(:build) { create(:ci_build, :running, pipeline: pipeline) }
    let!(:new_pipeline) { create(:ci_pipeline, project: train_car.project) }

    before do
      train_car.update!(pipeline: pipeline)
    end

    it 'cancels the existing pipeline', :sidekiq_inline do
      expect { subject }.to change { build.reload.status }.from('running').to('canceled')

      pipeline.reload

      expect(pipeline.status).to eq('canceled')
      expect(pipeline.auto_canceled_by).to eq(new_pipeline)
    end
  end

  describe '#mergeable?' do
    subject { train_car.mergeable? }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    context 'when merge train has successful pipeline' do
      before do
        train_car.update!(pipeline: create(:ci_pipeline, :success, project: merge_request.project))
      end

      context 'when merge request is first on train' do
        it { is_expected.to be_truthy }
      end

      context 'when the other merge request is on the merge train' do
        let(:train_car) { merge_request_2.merge_train_car }
        let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

        it { is_expected.to be_falsy }
      end
    end

    context 'when merge train has non successful pipeline' do
      before do
        train_car.update!(pipeline: create(:ci_pipeline, :failed, project: merge_request.project))
      end

      context 'when merge request is first on train' do
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '#index' do
    subject { train_car.index }

    let(:train_car) { merge_request.merge_train_car }
    let!(:merge_request) { create_merge_request_on_train }

    it { is_expected.to eq(0) }

    context 'when the merge train is at the second queue' do
      let(:train_car) { merge_request_2.merge_train_car }
      let!(:merge_request_2) { create_merge_request_on_train(source_branch: 'improve/awesome') }

      it { is_expected.to eq(1) }
    end
  end

  describe 'status transition' do
    context 'when status is idle' do
      let(:train_car) { create(:merge_train_car) }

      context 'and transits to fresh' do
        let!(:pipeline) { create(:ci_pipeline) }

        it 'refreshes the state and set a pipeline' do
          train_car.refresh_pipeline!(pipeline.id)

          expect(train_car).to be_fresh
          expect(train_car.pipeline).to eq(pipeline)
        end
      end

      context 'and transits to merged' do
        it 'does not allow the transition' do
          expect { train_car.finish_merge! }
            .to raise_error(StateMachines::InvalidTransition)
        end
      end

      context 'and transits to stale' do
        it 'does not allow the transition' do
          expect { train_car.outdate_pipeline! }
            .to raise_error(StateMachines::InvalidTransition)
        end
      end
    end

    context 'when status is fresh' do
      let(:train_car) { create(:merge_train_car, :fresh) }

      context 'and transits to merged' do
        it 'does not allow the transition' do
          expect { train_car.finish_merge! }
            .to raise_error(StateMachines::InvalidTransition)
        end
      end

      context 'and transits to stale' do
        it 'refreshes asynchronously' do
          expect(MergeTrains::RefreshWorker)
            .to receive(:perform_async).with(train_car.target_project_id, train_car.target_branch).once

          train_car.outdate_pipeline!
        end
      end
    end

    context 'when status is merging' do
      let!(:train_car) { create(:merge_train_car, :merging) }

      context 'and transits to merged' do
        it 'persists duration and merged_at' do
          expect(train_car.duration).to be_nil
          expect(train_car.merged_at).to be_nil

          travel_to(1.hour.from_now) do
            train_car.finish_merge!

            train_car.reload
            expect(train_car.merged_at.to_i).to eq(Time.current.to_i)
            expect(train_car.duration).to be_within(1.hour.to_i).of(1.hour.to_i + 1)
          end
        end

        it 'cleans up train car ref' do
          expect(train_car).to receive(:cleanup_ref)

          train_car.finish_merge!
        end
      end
    end

    context 'when status is merged' do
      let(:train_car) { create(:merge_train_car, :merged) }

      context 'and transits to merged' do
        it 'does not allow the transition' do
          expect { train_car.finish_merge! }
            .to raise_error(StateMachines::InvalidTransition)
        end
      end
    end
  end

  describe '#destroy' do
    subject { train_car.destroy! }

    context 'when merge train has a pipeline' do
      let(:train_car) { create(:merge_train_car, pipeline: pipeline) }
      let(:pipeline) { create(:ci_pipeline, :running) }
      let(:build) { create(:ci_build, :running, pipeline: pipeline) }

      it 'cancels the jobs in the pipeline' do
        expect { subject }.to change { build.reload.status }.from('running').to('canceled')
      end
    end
  end

  describe '#cleanup_ref' do
    subject { train_car.cleanup_ref }

    let(:train_car) { create(:merge_train_car) }

    it 'executes cleanup_refs for merge request' do
      expect(train_car.merge_request).to receive(:cleanup_refs).with(only: :train)

      subject
    end
  end

  describe '#active?' do
    subject { train_car.active? }

    context 'when status is idle' do
      let(:train_car) { create(:merge_train_car, :idle) }

      it { is_expected.to eq(true) }
    end

    context 'when status is merged' do
      let(:train_car) { create(:merge_train_car, :merged) }

      it { is_expected.to eq(false) }
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

  context 'with loose foreign key on merge_trains.pipeline_id' do
    it_behaves_like 'cleanup by a loose foreign key' do
      let!(:parent) { create(:ci_pipeline) }
      let!(:model) { create(:merge_train_car, pipeline: parent) }
    end
  end
end
