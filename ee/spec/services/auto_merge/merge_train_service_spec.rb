# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::MergeTrainService, feature_category: :merge_trains do
  include ExclusiveLeaseHelpers

  let_it_be(:project) { create(:project, :repository, merge_pipelines_enabled: true, merge_trains_enabled: true) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user, params) }
  let(:params) { {} }

  let(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline,
      source_project: project, target_project: project)
  end

  before do
    project.add_maintainer(user)

    allow(AutoMergeProcessWorker).to receive(:perform_async) {}

    stub_feature_flags(disable_merge_trains: false)
    stub_licensed_features(merge_trains: true, merge_pipelines: true)
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    it 'enables auto merge on the merge request' do
      subject

      merge_request.reload
      expect(merge_request.auto_merge_enabled).to be_truthy
      expect(merge_request.merge_user).to eq(user)
      expect(merge_request.auto_merge_strategy).to eq(AutoMergeService::STRATEGY_MERGE_TRAIN)
    end

    it 'creates merge train' do
      subject

      merge_request.reload
      expect(merge_request.merge_train_car).to be_present
      expect(merge_request.merge_train_car.user).to eq(user)
    end

    it 'creates system note' do
      expect(SystemNoteService)
        .to receive(:merge_train).with(merge_request, project, user, MergeTrains::Car)

      subject
    end

    it 'returns result code' do
      is_expected.to eq(:merge_train)
    end

    context 'when failed to save the record' do
      before do
        allow(merge_request).to receive(:save!) { raise PG::QueryCanceled }
      end

      it 'returns result code' do
        is_expected.to eq(:failed)
      end
    end

    context 'when statement timeout happened on system note creation' do
      before do
        allow(SystemNoteService).to receive(:merge_train) { raise PG::QueryCanceled }
      end

      it 'returns failed status' do
        is_expected.to eq(:failed)
      end

      it 'rollback the transaction' do
        expect { subject }.not_to change { Note.count }

        merge_request.reload
        expect(merge_request).not_to be_auto_merge_enabled
        expect(merge_request.merge_train_car).not_to be_present
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception).with(kind_of(PG::QueryCanceled),
                                             merge_request_id: merge_request.id)

        subject
      end
    end
  end

  describe '#process' do
    subject { service.process(merge_request) }

    let(:merge_request) do
      create(:merge_request, :on_train,
        source_project: project, source_branch: 'feature',
        target_project: project, target_branch: 'master')
    end

    it 'calls RefreshWorker' do
      expect(MergeTrains::RefreshWorker)
        .to receive(:perform_async)
        .with(merge_request.target_project_id, merge_request.target_branch)
        .once

      subject
    end

    context 'when merge request is not on a merge train' do
      let(:merge_request) { create(:merge_request) }

      it 'does not call RefreshWorker' do
        expect(MergeTrains::RefreshWorker).not_to receive(:perform_async)

        subject
      end
    end
  end

  describe '#cancel' do
    subject { service.cancel(merge_request, **params) }

    let(:params) { {} }

    let!(:merge_request) do
      create(:merge_request, :on_train,
        source_project: project, source_branch: 'feature',
        target_project: project, target_branch: 'master')
    end

    it 'cancels auto merge on the merge request' do
      subject

      merge_request.reload
      expect(merge_request).not_to be_auto_merge_enabled
      expect(merge_request.merge_user).to be_nil
      expect(merge_request.merge_params).not_to include('should_remove_source_branch')
      expect(merge_request.merge_params).not_to include('commit_message')
      expect(merge_request.merge_params).not_to include('squash_commit_message')
      expect(merge_request.merge_params).not_to include('auto_merge_strategy')
      expect(merge_request.merge_train_car).not_to be_present
    end

    it 'writes system note to the merge request' do
      expect(SystemNoteService)
        .to receive(:cancel_merge_train).with(merge_request, project, user)

      subject
    end

    context 'when pipeline exists' do
      before do
        merge_request.merge_train_car.update!(pipeline: pipeline)
      end

      let(:pipeline) { create(:ci_pipeline) }
      let(:build) { create(:ci_build, :running, pipeline: pipeline) }

      it 'cancels the jobs in the pipeline' do
        expect { subject }.to change { build.reload.status }.from('running').to('canceled')
      end
    end

    context 'when train ref exists' do
      before do
        merge_request.project.repository.create_ref(merge_request.target_branch, merge_request.train_ref_path)
      end

      it 'deletes train ref' do
        expect { subject }
          .to change { merge_request.project.repository.ref_exists?(merge_request.train_ref_path) }
          .from(true).to(false)
      end
    end

    context 'when train ref does not exist' do
      it 'does not raise an error' do
        expect { subject }.not_to raise_error
      end
    end

    context 'when the other merge request is following the merge request' do
      let!(:merge_request_2) do
        create(:merge_request, :on_train,
          source_project: project, source_branch: 'signed-commits',
          target_project: project, target_branch: 'master',
          status: status)
      end

      let(:status) { MergeTrains::Car.state_machines[:status].states[:fresh].value }

      it 'processes the train by default' do
        expect(MergeTrains::RefreshWorker).to receive(:perform_async).with(merge_request_2.target_project_id, merge_request_2.target_branch)

        subject

        expect(merge_request_2.reset.merge_train_car).to be_stale
      end

      context 'when the status is stale already' do
        let(:status) { MergeTrains::Car.state_machines[:status].states[:stale].value }

        it 'does not do anything' do
          expect(MergeTrains::RefreshWorker).not_to receive(:perform_async)

          expect { subject }.not_to raise_error

          expect(merge_request_2.reset.merge_train_car).to be_stale
        end
      end
    end

    context 'when statement timeout happened on system note creation' do
      before do
        allow(SystemNoteService).to receive(:cancel_merge_train) { raise PG::QueryCanceled }
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq("Can't cancel the automatic merge")
      end

      it 'rollback the transaction' do
        expect { subject }.not_to change { Note.count }

        merge_request.reload
        expect(merge_request).to be_auto_merge_enabled
        expect(merge_request.merge_train_car).to be_present
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception).with(kind_of(PG::QueryCanceled),
                                             merge_request_id: merge_request.id)

        subject
      end
    end
  end

  describe '#abort' do
    subject { service.abort(merge_request, 'an error', **args) }

    let!(:merge_request) do
      create(:merge_request, :on_train,
        source_project: project, source_branch: 'feature',
        target_project: project, target_branch: 'master')
    end

    let(:args) { {} }

    it 'aborts auto merge on the merge request' do
      subject

      merge_request.reload
      expect(merge_request).not_to be_auto_merge_enabled
      expect(merge_request.merge_user).to be_nil
      expect(merge_request.merge_params).not_to include('should_remove_source_branch')
      expect(merge_request.merge_params).not_to include('commit_message')
      expect(merge_request.merge_params).not_to include('squash_commit_message')
      expect(merge_request.merge_params).not_to include('auto_merge_strategy')
      expect(merge_request.merge_train_car).not_to be_present
    end

    it 'writes system note to the merge request' do
      expect(SystemNoteService)
        .to receive(:abort_merge_train).with(merge_request, project, user, 'an error')

      subject
    end

    context 'when the other merge request is following the merge request' do
      let!(:merge_request_2) do
        create(:merge_request, :on_train,
          source_project: project, source_branch: 'signed-commits',
          target_project: project, target_branch: 'master',
          status: MergeTrains::Car.state_machines[:status].states[:fresh].value)
      end

      it 'processes the train' do
        expect(MergeTrains::RefreshWorker).to receive(:perform_async).with(merge_request_2.target_project_id, merge_request_2.target_branch)

        subject

        expect(merge_request_2.reset.merge_train_car).to be_stale
      end

      context 'when process_next is false' do
        let(:args) { { process_next: false } }

        it 'does not process the next merge request on the train' do
          expect(MergeTrains::RefreshWorker).not_to receive(:perform_async)

          subject
        end
      end
    end

    context 'when statement timeout happened on system note creation' do
      before do
        allow(SystemNoteService).to receive(:abort_merge_train) { raise PG::QueryCanceled }
      end

      it 'returns error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq("Can't abort the automatic merge")
      end

      it 'rollback the transaction' do
        expect { subject }.not_to change { Note.count }

        merge_request.reload
        expect(merge_request).to be_auto_merge_enabled
        expect(merge_request.merge_train_car).to be_present
      end

      it 'tracks the exception' do
        expect(Gitlab::ErrorTracking)
          .to receive(:track_exception).with(kind_of(PG::QueryCanceled),
                                             merge_request_id: merge_request.id)

        subject
      end
    end
  end

  describe '#available_for?' do
    subject { service.available_for?(merge_request) }

    let(:pipeline) { double }

    before do
      allow(merge_request).to receive(:mergeable_state?) { true }
      allow(merge_request).to receive(:for_fork?) { false }
      allow(merge_request).to receive(:actual_head_pipeline) { pipeline }
      allow(pipeline).to receive(:complete?) { true }
    end

    it { is_expected.to be_truthy }

    it 'memoizes the result' do
      expect(merge_request).to receive(:can_be_merged_by?).once.and_call_original

      2.times { is_expected.to be_truthy }
    end

    context 'when merge trains flag is disabled' do
      before do
        project.update!(merge_trains_enabled: false)
      end

      it { is_expected.to be_falsy }
    end

    context 'when there is an open MR dependency' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
        create(:merge_request_block, blocked_merge_request: merge_request)
      end

      it { is_expected.to be_falsy }
    end

    context 'when merge train ci setting is disabled' do
      before do
        stub_feature_flags(disable_merge_trains: true)
      end

      it { is_expected.to be_falsy }
    end

    context 'when merge request is not mergeable' do
      before do
        allow(merge_request).to receive(:mergeable_state?) { false }
      end

      it { is_expected.to be_falsy }
    end

    context 'when the user does not have permission to merge' do
      before do
        allow(merge_request).to receive(:can_be_merged_by?) { false }
      end

      it { is_expected.to be_falsy }
    end

    context 'when the head pipeline of the merge request has not finished' do
      before do
        allow(pipeline).to receive(:complete?) { false }
      end

      it { is_expected.to be_falsy }
    end
  end

  def create_pipeline_for(merge_request)
    MergeRequests::CreatePipelineService.new(project: project, current_user: user).execute(merge_request)
  end
end
