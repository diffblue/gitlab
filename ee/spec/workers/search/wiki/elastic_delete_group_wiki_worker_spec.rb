# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::Wiki::ElasticDeleteGroupWikiWorker, feature_category: :global_search do
  describe '#perform', :elastic, :sidekiq_inline do
    let_it_be(:wiki) { create(:group_wiki) }
    let_it_be(:wiki2) { create(:group_wiki) }
    let(:project_wiki) { project.wiki }
    let(:group) { wiki.container }
    let(:group2) { wiki2.container }
    let_it_be(:project) { create(:project, :wiki_repo) }

    before do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      [wiki, wiki2, project_wiki].each.with_index do |wiki, idx|
        wiki.create_page("index_page#{idx}", 'Bla bla term')
        wiki.index_wiki_blobs
      end
      ensure_elasticsearch_index!
    end

    it 'removes all the wikis in the Elastic of the passed group' do
      expect(get_wiki_documents_count(group.id, group.class.name)).to be 1
      described_class.new.perform(group.id)
      refresh_index!
      expect(get_wiki_documents_count(group.id, group.class.name)).to be 0
      expect(get_wiki_documents_count(group2.id, group2.class.name)).to be 1
      expect(get_wiki_documents_count(project.id, project.class.name)).to be 1
    end

    def get_wiki_documents_count(container_id, container_type)
      Gitlab::Elastic::Helper.default.client.search(
        {
          index: Elastic::Latest::WikiConfig.index_name,
          routing: "#{container_type.downcase}_#{container_id}",
          body: {
            query: {
              bool: {
                filter: {
                  term: {
                    rid: "wiki_#{container_type.downcase}_#{container_id}"
                  }
                }
              }
            }
          }
        }
      )['hits']['total']['value']
    end
  end
end
