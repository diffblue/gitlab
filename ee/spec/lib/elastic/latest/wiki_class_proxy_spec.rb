# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::WikiClassProxy, feature_category: :global_search do
  let_it_be(:project) { create(:project, :wiki_repo) }

  subject { described_class.new(project.wiki.class, use_separate_indices: ProjectWiki.use_separate_indices?) }

  describe '#elastic_search_as_wiki_page', :elastic do
    let!(:page) { create(:wiki_page, wiki: project.wiki) }

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

      Gitlab::Elastic::Indexer.new(project, wiki: true).run
      ensure_elasticsearch_index!
    end

    it 'returns FoundWikiPage', :sidekiq_inline do
      results = subject.elastic_search_as_wiki_page('*')

      expect(results.size).to eq(1)
      expect(results).to all(be_a(Gitlab::Search::FoundWikiPage))

      result = results.first

      expect(result.path).to eq(page.path)
      expect(result.startline).to eq(1)
      expect(result.data).to include(page.content)
      expect(result.project).to eq(project)
    end
  end

  it 'names elasticsearch queries', :elastic do
    subject.elastic_search_as_wiki_page('*')

    assert_named_queries('doc:is_a:wiki_blob', 'blob:match:search_terms')
  end

  describe '#routing_options' do
    let(:n_routing) { 'n_1,n_2,n_3' }
    let(:ids) { [1, 2, 3] }
    let(:default_ops) { { root_ancestor_ids: ids, scope: 'wiki_blob' } }

    context 'when routing is disabled' do
      context 'and option routing_disabled is set' do
        it 'returns empty hash' do
          expect(subject.routing_options(default_ops.merge(routing_disabled: true))).to be_empty
        end
      end

      context 'and option public_and_internal_projects is set' do
        it 'returns empty hash' do
          expect(subject.routing_options(default_ops.merge(public_and_internal_projects: true))).to be_empty
        end
      end
    end

    context 'when ids count are more than 128' do
      it 'returns empty hash' do
        max_count = Elastic::Latest::Routing::ES_ROUTING_MAX_COUNT
        expect(subject.routing_options(default_ops.merge(root_ancestor_ids: 1.upto(max_count + 1).to_a))).to be_empty
      end
    end

    it 'returns routing hash' do
      expect(subject.routing_options(default_ops)).to eq({ routing: n_routing })
    end
  end
end
