# frozen_string_literal: true

require 'spec_helper'
require_relative 'migration_shared_examples'
require File.expand_path('ee/elastic/migrate/20230702000000_backfill_existing_group_wiki.rb')

RSpec.describe BackfillExistingGroupWiki, :elastic_clean, :sidekiq_inline, feature_category: :global_search do
  let(:version) { 20230702000000 }
  let(:migration) { described_class.new(version) }
  let(:wiki) { create(:group_wiki) }
  let(:group) { wiki.container }
  let(:wiki2) { create(:group_wiki) }
  let(:group2) { wiki2.container }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to(version, including: false)
    [wiki, wiki2].each do |w|
      w.create_page('index_page', 'Bla bla term')
      w.index_wiki_blobs
    end
    ensure_elasticsearch_index!
  end

  describe 'migration_options' do
    it 'has migration options set', :aggregate_failures do
      expect(migration).to be_batched
      expect(migration).to be_retry_on_failure
      expect(migration.throttle_delay).to eq(5.minutes)
      expect(migration.batch_size).to eq(200)
    end
  end

  describe '.completed?' do
    subject { migration.completed? }

    context 'when all the group wikis have been indexed' do
      before do
        migration.migrate
      end

      it 'returns true with a log' do
        expect(migration).to receive(:log).with('All Groups needed to be indexed are indexed',
          { last_group_id: GroupWikiRepository.maximum(:group_id), completed: true })
        is_expected.to be true
      end
    end

    context 'when there are no GroupWikiRepository record' do
      before do
        GroupWikiRepository.delete_all
      end

      it 'returns true with a log' do
        expect(migration).to receive(:log).with('GroupWikiRepository is empty', { completed: true })
        is_expected.to be true
      end
    end

    context 'when max_processed_group_id is less than maximum_group_id' do
      it 'returns false with a log' do
        expect(migration).to receive(:log).with('Indexing is in progress', { last_group_id: 0, completed: false })
        is_expected.to be false
      end
    end
  end

  describe '.migrate' do
    let(:client) { ::Gitlab::Search::Client.new }
    let(:helper) { Gitlab::Elastic::Helper.new }

    before do
      allow(migration).to receive(:client).and_return(client)
      allow(migration).to receive(:helper).and_return(helper)
      remove_all_group_wikis
    end

    it 'indexes all the groups' do
      migration.migrate
      refresh_index!
      es_response = client.search(index: "#{helper.target_name}-wikis")['hits']['hits']
      expect(es_response.map { |hit| hit['_source']['group_id'] }).to contain_exactly group.id, group2.id
    end

    context 'when completed? is true' do
      before do
        allow(migration).to receive(:completed?).and_return true
      end

      it 'makes an early return' do
        expect(migration.migrate).to be nil
        refresh_index!
        es_response = client.search(index: "#{helper.target_name}-wikis")['hits']['hits']
        expect(es_response.map { |hit| hit['_source']['group_id'] }).to be_empty
      end
    end

    def remove_all_group_wikis
      helper.client.delete_by_query(
        index: Elastic::Latest::WikiConfig.index_name,
        routing: "n_#{group.id},n_#{group2.id}",
        conflicts: 'proceed',
        refresh: true,
        body: { query: { regexp: { rid: "wiki_group_[0-9].*" } } }
      )
    end
  end
end
