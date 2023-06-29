# frozen_string_literal: true

require 'spec_helper'
require File.expand_path('ee/elastic/migrate/20230519500012_reindex_wikis_to_fix_permissions_and_traversal_ids.rb')

RSpec.describe ReindexWikisToFixPermissionsAndTraversalIds, :elastic_clean, :sidekiq_inline, feature_category: :global_search do
  let(:migration) { described_class.new(20230519500012) }
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:client) { ::Gitlab::Search::Client.new }
  let_it_be(:project) { create(:project, :wiki_repo) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    allow(migration).to receive(:helper).and_return(helper)
    set_elasticsearch_migration_to :reindex_wikis_to_fix_permissions_and_traversal_ids, including: false
    allow(migration).to receive(:client).and_return(client)
    project.wiki.create_page('index_page', 'Bla bla term')
    project.wiki.create_page('index_page2', 'Bla bla term')
    project.wiki.index_wiki_blobs
    ensure_elasticsearch_index! # ensure objects are indexed
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration.batch_size).to eq 200
      expect(migration.throttle_delay).to eq(5.minutes)
      expect(migration).to be_retry_on_failure
    end
  end

  describe '.migrate' do
    context 'if migration is completed' do
      it 'performs logging and does not call ElasticWikiIndexerWorker' do
        expect(migration).to receive(:log).with("Setting migration_state to #{{ documents_remaining: 0 }.to_json}").once
        expect(migration).to receive(:log).with('Checking if migration is finished', { total_remaining: 0 }).once
        expect(migration).to receive(:log).with('Migration Completed', { total_remaining: 0 }).once
        expect(ElasticWikiIndexerWorker).not_to receive(:perform_in)
        migration.migrate
      end
    end

    context 'if migration is not completed' do
      before do
        set_old_schema_version_in_one_document!
      end

      it 'performs logging and calls ElasticWikiIndexerWorker' do
        expect(migration).to receive(:log).with("Setting migration_state to #{{ documents_remaining: 1 }.to_json}").once
        expect(migration).to receive(:log).with('Checking if migration is finished', { total_remaining: 1 }).once
        expect(ElasticWikiIndexerWorker).to receive(:perform_in)
        migration.migrate
      end
    end
  end

  describe '.completed?' do
    subject { migration.completed? }

    let_it_be(:project) { create(:project, :wiki_repo) }

    context 'when all the documents have the new schema_version(2305)' do
      # With the 4.3.3 GITLAB_ELASTICSEARCH_INDEXER_VERSION all the new wikis will have schema_version 2305
      it 'returns true' do
        is_expected.to be true
      end
    end

    context 'when some items are missing project prefix in rid' do
      before do
        set_old_schema_version_in_one_document!
      end

      it 'returns false' do
        is_expected.to be false
      end
    end
  end

  def set_old_schema_version_in_one_document!
    client.update_by_query(index: Elastic::Latest::WikiConfig.index_name, max_docs: 1, refresh: true,
      body: { script: { lang: 'painless', source: 'ctx._source.schema_version = 2303' } }
    )
  end
end
