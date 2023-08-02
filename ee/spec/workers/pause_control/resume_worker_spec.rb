# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PauseControl::ResumeWorker, feature_category: :global_search do
  subject(:worker) { described_class.new }

  let(:worker_with_pause_control) { Zoekt::IndexerWorker }

  describe '#perform' do
    context 'when zoekt workers are paused' do
      before do
        stub_feature_flags(zoekt_pause_indexing: true)
      end

      it 'does not resume processing' do
        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService)
          .not_to receive(:resume_processing!)
          .with(worker_with_pause_control.name)

        worker.perform
      end
    end

    context 'when zoekt workers are not paused' do
      before do
        stub_feature_flags(zoekt_pause_indexing: false)
        allow(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService)
          .to receive(:has_jobs_in_waiting_queue?)
      end

      it 'pauses inactive strategies and reschedues a job' do
        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService)
          .to receive(:has_jobs_in_waiting_queue?)
          .with(worker_with_pause_control.name)
          .and_return(1)

        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService)
          .to receive(:resume_processing!)
          .with(worker_with_pause_control.name)
          .and_return(1)

        expect(described_class).to receive(:perform_in).with(described_class::RESCHEDULE_DELAY)

        worker.perform
      end

      it 'does not reschedules the job' do
        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService)
          .to receive(:has_jobs_in_waiting_queue?)
          .with(worker_with_pause_control.name)
          .and_return(1)

        expect(Gitlab::SidekiqMiddleware::PauseControl::PauseControlService)
          .to receive(:resume_processing!)
          .with(worker_with_pause_control.name)
          .and_return(0)

        expect(described_class).not_to receive(:perform_in)

        worker.perform
      end
    end
  end
end
