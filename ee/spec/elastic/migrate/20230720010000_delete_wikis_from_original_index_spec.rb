# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20230720010000_delete_wikis_from_original_index.rb')

RSpec.describe DeleteWikisFromOriginalIndex, feature_category: :global_search do
  let(:version) { 20230720010000 }
  let(:migration) { described_class.new(version) }
  let(:helper) { Gitlab::Elastic::Helper.new }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration.batched?).to be_truthy
      expect(migration.batch_size).to eq(1000)
      expect(migration).to be_retry_on_failure
    end
  end

  describe '.migrate', :elastic, :sidekiq_inline do
    let_it_be(:project) { create(:project, :public, :repository, :wiki_repo) }
    let(:client) { ::Gitlab::Search::Client.new }

    before do
      allow(migration).to receive(:client).and_return(client)
      set_elasticsearch_migration_to :migrate_wikis_to_separate_index, including: false
      5.times do |i|
        project.wiki.create_page("test#{i}", 'test')
        project.wiki.index_wiki_blobs
      end
      ensure_elasticsearch_index! # ensure objects are indexed
    end

    context 'when wikis are still present in the index' do
      it 'removes wikis from the index' do
        expect(migration.completed?).to be_falsey
        migration.migrate
        expect(migration.migration_state).to match(documents_remaining: anything, task_id: anything)
        # the migration might not complete after the initial task is created
        # so make sure it actually completes
        10.times do
          migration.migrate
          break if migration.completed?
        end

        expect(migration.completed?).to be_truthy
        expect(migration.migration_state).to match(task_id: nil, documents_remaining: 0)
      end

      context 'and task in progress' do
        before do
          allow(migration).to receive(:completed?).and_return(false)
          allow(migration).to receive(:client).and_return(client)
          allow(helper).to receive(:task_status).and_return('completed' => false)
          migration.set_migration_state(task_id: 'task_1')
        end

        it 'does nothing if task is not completed' do
          migration.migrate
          expect(client).not_to receive(:delete_by_query)
        end
      end
    end

    context 'when migration fails' do
      context 'with exception is raised' do
        before do
          allow(client).to receive(:delete_by_query).and_raise(StandardError)
        end

        it 'resets task_id' do
          migration.set_migration_state(task_id: 'task_1')
          expect { migration.migrate }.to raise_error(StandardError)
          expect(migration.migration_state).to match(task_id: nil, documents_remaining: anything)
        end
      end

      context 'with task throws an error' do
        before do
          allow(client).to receive(:delete_by_query).and_return('task' => 'task_1')
          allow(migration).to receive(:get_number_of_shards).and_return(1)
          allow(helper).to receive(:task_status).and_return('error' => ['failed'])
          migration.migrate
        end

        it 'resets task_id' do
          expect { migration.migrate }.to raise_error(/Failed to delete wikis/)
          expect(migration.migration_state).to match(task_id: nil, documents_remaining: anything)
        end
      end
    end

    context 'when wikis are already deleted' do
      before do
        client.delete_by_query(index: helper.target_name,
          body: { query: { bool: { filter: { term: { type: 'wiki_blob' } } } } })
      end

      it 'does not execute delete_by_query' do
        expect(migration.completed?).to be_truthy
        expect(helper.client).not_to receive(:delete_by_query)
        migration.migrate
      end
    end
  end

  describe '.completed?' do
    context 'when original_documents_count is zero' do
      before do
        allow(migration).to receive(:original_documents_count).and_return 0
      end

      it 'returns true' do
        expect(migration.completed?).to eq true
      end
    end

    context 'when original_documents_count is non zero' do
      before do
        allow(migration).to receive(:original_documents_count).and_return 1
      end

      it 'returns false' do
        expect(migration.completed?).to eq false
      end
    end
  end
end
