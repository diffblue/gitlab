# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticCommitIndexerWorker, feature_category: :global_search do
  let_it_be(:project) { create(:project, :repository) }

  let(:logger_double) { instance_double(Gitlab::Elasticsearch::Logger) }

  subject(:worker) { described_class.new }

  describe '#perform' do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    it 'runs indexer' do
      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run)
      end

      worker.perform(project.id, false)
    end

    it 'logs timing information' do
      allow_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        allow(indexer).to receive(:run).and_return(true)
      end

      expect(Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger_double.as_null_object)

      expect(logger_double).to receive(:info).with(
        project_id: project.id,
        wiki: false,
        search_indexing_duration_s: an_instance_of(Float),
        jid: anything
      )

      worker.perform(project.id, false)
    end

    it 'records the apdex SLI' do
      allow_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        allow(indexer).to receive(:run).and_return(true)
      end

      expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_apdex).with(
        elapsed: a_kind_of(Numeric),
        document_type: 'Code'
      )

      worker.perform(project.id)
    end

    context 'when force is not set' do
      before do
        allow_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          allow(indexer).to receive(:run).and_return(true)
        end
      end

      it 'does not log extra metadata on done for code' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform(project.id, false)
      end

      it 'does not log extra metadata on done for wiki' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform(project.id, true)
      end
    end

    context 'when force is set' do
      let_it_be(:stats) { create(:project_statistics, with_data: true, project: project, commit_count: 10) }

      before do
        allow_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          allow(indexer).to receive(:run).and_return(true)
        end
      end

      it 'logs extra metadata on done when run for code', :aggregate_failures do
        expect(worker).to receive(:log_extra_metadata_on_done).with(:commit_count, 10)
        expect(worker).to receive(:log_extra_metadata_on_done).with(:repository_size, 1)

        worker.perform(project.id, false, { 'force' => true })
      end

      it 'does not log extra metadata on done when run for wiki' do
        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform(project.id, true, { 'force' => true })
      end
    end

    context 'when ES is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'returns true' do
        expect(Gitlab::Elastic::Indexer).not_to receive(:new)

        expect(worker.perform(project.id)).to be_truthy
      end

      it 'does not log anything' do
        expect(logger_double).not_to receive(:info)

        worker.perform(project.id)
      end

      it 'does not record the apdex SLI' do
        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)

        worker.perform(project.id)
      end
    end

    it 'runs indexer in wiki mode if asked to' do
      indexer = double

      expect(indexer).to receive(:run)
      expect(Gitlab::Elastic::Indexer).to receive(:new).with(project, wiki: true, force: false).and_return(indexer)

      worker.perform(project.id, true)
    end

    context 'when the indexer is locked' do
      it 'does not run index' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer.timeout + 1.minute), retries: 0)

        expect(Gitlab::Elastic::Indexer).not_to receive(:new)

        worker.perform(project.id)
      end

      it 'does not log anything' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer.timeout + 1.minute), retries: 0)

        expect(logger_double).not_to receive(:info)

        worker.perform(project.id)
      end

      it 'does not record the apdex SLI' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer.timeout + 1.minute), retries: 0)

        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)

        worker.perform(project.id)
      end

      it 'does not log extra metadata' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer.timeout + 1.minute), retries: 0)

        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform(project.id)
      end
    end

    context 'when the indexer fails' do
      it 'does not log anything' do
        expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          expect(indexer).to receive(:run).and_return false
        end

        expect(logger_double).not_to receive(:info)

        worker.perform(project.id)
      end

      it 'does not record the apdex SLI' do
        expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          expect(indexer).to receive(:run).and_return false
        end

        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)

        worker.perform(project.id)
      end

      it 'does not log extra metadata' do
        expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          expect(indexer).to receive(:run).and_return false
        end

        expect(worker).not_to receive(:log_extra_metadata_on_done)

        worker.perform(project.id)
      end
    end
  end
end
