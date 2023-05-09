# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectWiki, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:project) { create(:project, :wiki_repo) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.wiki.create_page('index_page', 'Bla bla term1')
    project.wiki.create_page('omega_page', 'Bla bla term2')
    project.wiki.index_wiki_blobs

    ensure_elasticsearch_index!
  end

  describe '#use_elasticsearch?' do
    it 'delegates to Project#use_elasticsearch?' do
      expect(project).to receive(:use_elasticsearch?)

      project.wiki.use_elasticsearch?
    end
  end

  it 'searches wiki page' do
    expect(project.wiki.elastic_search('term1', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(1)
    expect(project.wiki.elastic_search('term1 | term2', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(2)
  end

  it 'indexes using ElasticWikiIndexerWorker if feature_flag separate_elastic_wiki_indexer_for_project is enabled' do
    expect(ElasticWikiIndexerWorker).to receive(:perform_async).with(project.id, project.class.name)

    project.wiki.index_wiki_blobs
  end

  it 'indexes using ElasticCommitIndexerWorker if feature_flag separate_elastic_wiki_indexer_for_project is disabled' do
    stub_feature_flags(separate_elastic_wiki_indexer_for_project: false)
    expect(ElasticCommitIndexerWorker).to receive(:perform_async).with(project.id, true)

    project.wiki.index_wiki_blobs
  end

  it 'can delete wiki pages' do
    expect(project.wiki.elastic_search('term2', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(1)

    Sidekiq::Testing.inline! do
      project.wiki.find_page('omega_page').delete

      expect_next_instance_of(Gitlab::Elastic::Indexer) do |indexer|
        expect(indexer).to receive(:run).and_call_original
      end

      project.wiki.index_wiki_blobs

      ensure_elasticsearch_index!
    end

    expect(project.wiki.elastic_search('term2', type: 'wiki_blob')[:wiki_blobs][:total_count]).to eq(0)
  end
end
