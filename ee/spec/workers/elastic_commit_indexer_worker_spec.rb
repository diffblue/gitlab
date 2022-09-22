# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticCommitIndexerWorker do
  let!(:project) { create(:project, :repository) }
  let(:logger_double) { instance_double(Gitlab::Elasticsearch::Logger) }

  subject { described_class.new }

  describe '#perform' do
    before do
      stub_ee_application_setting(elasticsearch_indexing: true)
    end

    it 'runs indexer' do
      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run)
      end

      subject.perform(project.id, false)
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

      subject.perform(project.id, false)
    end

    it 'records the apdex SLI' do
      allow_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        allow(indexer).to receive(:run).and_return(true)
      end

      expect(Gitlab::Metrics::GlobalSearchIndexingSlis).to receive(:record_apdex).with(
        elapsed: a_kind_of(Numeric),
        document_type: 'Code'
      )

      subject.perform(project.id)
    end

    context 'when ES is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'returns true' do
        expect(Gitlab::Elastic::Indexer).not_to receive(:new)

        expect(subject.perform(project.id)).to be_truthy
      end

      it 'does not log anything' do
        expect(logger_double).not_to receive(:info)

        subject.perform(project.id)
      end

      it 'does not record the apdex SLI' do
        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)

        subject.perform(project.id)
      end
    end

    it 'runs indexer in wiki mode if asked to' do
      indexer = double

      expect(indexer).to receive(:run)
      expect(Gitlab::Elastic::Indexer).to receive(:new).with(project, wiki: true, force: false).and_return(indexer)

      subject.perform(project.id, true)
    end

    context 'when the indexer is locked' do
      it 'does not run index' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer::TIMEOUT + 1.minute), retries: 0)

        expect(Gitlab::Elastic::Indexer).not_to receive(:new)

        subject.perform(project.id)
      end

      it 'does not log anything' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer::TIMEOUT + 1.minute), retries: 0)

        expect(logger_double).not_to receive(:info)

        subject.perform(project.id)
      end

      it 'does not record the apdex SLI' do
        expect(subject).to receive(:in_lock) # Mock and don't yield
          .with("ElasticCommitIndexerWorker/#{project.id}/false", ttl: (Gitlab::Elastic::Indexer::TIMEOUT + 1.minute), retries: 0)

        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)

        subject.perform(project.id)
      end
    end

    context 'when the indexer fails' do
      it 'does not log anything' do
        expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          expect(indexer).to receive(:run).and_return false
        end

        expect(logger_double).not_to receive(:info)

        subject.perform(project.id)
      end

      it 'does not record the apdex SLI' do
        expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
          expect(indexer).to receive(:run).and_return false
        end

        expect(Gitlab::Metrics::GlobalSearchIndexingSlis).not_to receive(:record_apdex)

        subject.perform(project.id)
      end
    end
  end
end
