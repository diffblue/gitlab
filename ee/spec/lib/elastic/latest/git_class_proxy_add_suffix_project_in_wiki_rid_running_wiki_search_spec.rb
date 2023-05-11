# frozen_string_literal: true

# This spec file can be removed once the migration add_suffix_project_in_wiki_rid is deprecated
require 'spec_helper'

RSpec.describe Elastic::Latest::GitClassProxy, :elastic, :sidekiq_inline, feature_category: :global_search do
  let_it_be(:wiki_project) { create(:project, :wiki_repo) }
  let(:included_class) { Elastic::Latest::RepositoryClassProxy }

  subject { included_class.new(wiki_project.repository) }

  it 'fetches the results considering new and old format of rid' do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    set_elasticsearch_migration_to(:add_suffix_project_in_wiki_rid, including: false)

    wiki_project.wiki.create_page('home_page', 'Bla bla term')
    wiki_project.wiki.create_page('home_page2', 'Bla bla term')
    wiki_project.wiki.index_wiki_blobs

    ensure_elasticsearch_index!

    # Remove the project from the rid in one document
    # It simulates a situtation where rid of some wiki blobs are already updated
    remove_project_from_wiki_blob_rid

    options = { repository_id: "wiki_project_#{wiki_project.id}" }

    results = subject.elastic_search('Bla', type: 'wiki_blob', options: options)[:wiki_blobs][:results]

    expect(results.total).to eq(2)
    result_rids = results.as_json.map { |r| r['_source']['rid'] }
    expect(result_rids).to include("wiki_project_#{wiki_project.id}", "wiki_#{wiki_project.id}")
  end

  def remove_project_from_wiki_blob_rid
    Project.__elasticsearch__.client.update_by_query({
      index: Elastic::Latest::WikiConfig.index_name, refresh: true, max_docs: 1,
      body: {
        script: {
          lang: 'painless',
          source: "ctx._source.rid = ctx._source.rid.replace('wiki_project', 'wiki')"
        },
        query: {
          regexp: {
            rid: "wiki_project_[0-9].*"
          }
        }
      }
    })
  end
end
