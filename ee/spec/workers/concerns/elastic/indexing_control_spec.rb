# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::IndexingControl, feature_category: :global_search do
  let!(:project) { create(:project, :repository) }

  let(:worker) do
    Class.new do
      def perform(project_id)
        project = Project.find(project_id)

        Gitlab::Elastic::Indexer.new(project).run
      end

      def self.name
        'DummyIndexingWorker'
      end

      include ApplicationWorker
      prepend Elastic::IndexingControl
    end.new
  end

  let(:worker_args) { [project.id] }
  let(:worker_context) { { 'correlation_id' => 'context_correlation_id' } }

  describe '::WORKERS' do
    it 'only includes classes which inherit from this class' do
      described_class::WORKERS.each do |klass|
        expect(klass.ancestors.first).to eq(described_class)
      end
    end
  end

  context 'with stub_const' do
    before do
      stub_const("Elastic::IndexingControl::WORKERS", [worker.class])
    end

    describe '.non_cached_pause_indexing?' do
      it 'calls current_without_cache' do
        expect(ApplicationSetting).to receive(:where).with(elasticsearch_pause_indexing: true).and_return(ApplicationSetting.none)

        expect(described_class.non_cached_pause_indexing?).to be_falsey
      end
    end

    describe '.resume_processing!' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(false)
      end

      it 'triggers job processing if there are jobs' do
        expect(Elastic::IndexingControlService).to receive(:has_jobs_in_waiting_queue?).with(worker.class).and_return(true)
        expect(Elastic::IndexingControlService).to receive(:resume_processing!).with(worker.class)

        described_class.resume_processing!
      end

      it 'does nothing if no jobs available' do
        expect(Elastic::IndexingControlService).to receive(:has_jobs_in_waiting_queue?).with(worker.class).and_return(false)
        expect(Elastic::IndexingControlService).not_to receive(:resume_processing!)

        described_class.resume_processing!
      end
    end

    context 'with elasticsearch indexing paused' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(true)
      end

      it 'adds jobs to the waiting queue' do
        expect_any_instance_of(Gitlab::Elastic::Indexer).not_to receive(:run)
        expect(Elastic::IndexingControlService).to receive(:add_to_waiting_queue!).with(worker.class, worker_args, worker_context)

        Gitlab::ApplicationContext.with_raw_context(worker_context) do
          worker.perform(*worker_args)
        end
      end

      it 'ignores changes from a different worker' do
        stub_const("Elastic::IndexingControl::WORKERS", [])

        expect_any_instance_of(Gitlab::Elastic::Indexer).to receive(:run)
        expect(Elastic::IndexingControlService).not_to receive(:add_to_waiting_queue!)

        worker.perform(*worker_args)
      end
    end

    context 'with elasticsearch indexing unpaused' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(false)
      end

      it 'performs the job' do
        expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          expect(indexer).to receive(:run)
        end
        expect(Elastic::IndexingControlService).not_to receive(:track!)

        worker.perform(*worker_args)
      end
    end
  end
end
