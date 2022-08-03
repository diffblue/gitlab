# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AutoMerge::AddToMergeTrainWhenPipelineSucceedsService do
  let_it_be(:project, reload: true) { create(:project, :repository) }
  let_it_be(:user) { create(:user) }

  let(:service) { described_class.new(project, user) }

  let(:merge_request) do
    create(:merge_request, :with_merge_request_pipeline,
      source_project: project, source_branch: 'feature',
      target_project: project, target_branch: 'master')
  end

  let(:pipeline) { merge_request.reload.all_pipelines.first }

  before do
    project.add_maintainer(user)
    project.update!(merge_pipelines_enabled: true, merge_trains_enabled: true)
    stub_feature_flags(disable_merge_trains: false)
    stub_licensed_features(merge_trains: true, merge_pipelines: true)
    allow(AutoMergeProcessWorker).to receive(:perform_async) {}
    merge_request.update_head_pipeline
  end

  describe '#execute' do
    subject { service.execute(merge_request) }

    it 'enables auto merge' do
      expect(SystemNoteService)
        .to receive(:add_to_merge_train_when_pipeline_succeeds)
        .with(merge_request, project, user, merge_request.actual_head_pipeline.sha)

      subject

      expect(merge_request).to be_auto_merge_enabled
    end
  end

  describe '#process' do
    subject { service.process(merge_request) }

    before do
      service.execute(merge_request)
    end

    context 'when the latest pipeline in the merge request has succeeded' do
      before do
        pipeline.succeed!
      end

      it 'executes MergeTrainService' do
        expect_next_instance_of(AutoMerge::MergeTrainService) do |train_service|
          expect(train_service).to receive(:execute).with(merge_request)
        end

        subject
      end

      context 'when merge train strategy is not available for the merge request' do
        before do
          train_service = double
          allow(train_service).to receive(:available_for?) { false }
          allow(AutoMerge::MergeTrainService).to receive(:new) { train_service }
        end

        it 'aborts auto merge' do
          expect(service).to receive(:abort).once.and_call_original

          expect(SystemNoteService)
            .to receive(:abort_add_to_merge_train_when_pipeline_succeeds).once
            .with(merge_request, project, user, 'This merge request cannot be added to the merge train')

          subject
        end
      end
    end

    context 'when the latest pipeline in the merge request is running' do
      it 'does not initialize MergeTrainService' do
        expect(AutoMerge::MergeTrainService).not_to receive(:new)

        subject
      end
    end
  end

  describe '#cancel' do
    subject { service.cancel(merge_request) }

    let(:merge_request) { create(:merge_request, :add_to_merge_train_when_pipeline_succeeds, merge_user: user) }

    it 'cancels auto merge' do
      expect(SystemNoteService)
        .to receive(:cancel_add_to_merge_train_when_pipeline_succeeds)
        .with(merge_request, project, user)

      subject

      expect(merge_request).not_to be_auto_merge_enabled
    end
  end

  describe '#abort' do
    subject { service.abort(merge_request, 'an error') }

    let(:merge_request) { create(:merge_request, :add_to_merge_train_when_pipeline_succeeds, merge_user: user) }

    it 'aborts auto merge' do
      expect(SystemNoteService)
        .to receive(:abort_add_to_merge_train_when_pipeline_succeeds)
        .with(merge_request, project, user, 'an error')

      subject

      expect(merge_request).not_to be_auto_merge_enabled
    end
  end

  describe '#available_for?' do
    subject { service.available_for?(merge_request) }

    it { is_expected.to eq(true) }

    it 'memoizes the result' do
      expect(merge_request).to receive(:can_be_merged_by?).once.and_call_original

      2.times { is_expected.to be_truthy }
    end

    context 'when merge trains option is disabled' do
      before do
        expect(merge_request.project).to receive(:merge_trains_enabled?) { false }
      end

      it { is_expected.to eq(false) }
    end

    context 'when the latest pipeline in the merge request is not active' do
      before do
        pipeline.succeed!
      end

      it { is_expected.to eq(false) }
    end

    context 'when merge request is not mergeable' do
      before do
        merge_request.update!(title: merge_request.draft_title)
      end

      it { is_expected.to eq(false) }
    end

    context 'when there is an open MR dependency' do
      before do
        stub_licensed_features(blocking_merge_requests: true)
        create(:merge_request_block, blocked_merge_request: merge_request)
      end

      it { is_expected.to be_falsy }
    end

    context 'when the user does not have permission to merge' do
      before do
        allow(merge_request).to receive(:can_be_merged_by?) { false }
      end

      it { is_expected.to be_falsy }
    end
  end
end
