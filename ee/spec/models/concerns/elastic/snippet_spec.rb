# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Snippet, :elastic do
  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
  end

  it 'always returns global result for Elasticsearch indexing for #use_elasticsearch?' do
    snippet = create :snippet

    expect(snippet.use_elasticsearch?).to eq(true)

    stub_ee_application_setting(elasticsearch_indexing: false)

    expect(snippet.use_elasticsearch?).to eq(false)
  end

  it 'searches snippets by title and description' do
    user = create(:user)

    Sidekiq::Testing.inline! do
      create(:snippet, :public, title: 'home')
      create(:snippet, :private, title: 'home 1')
      create(:snippet, :public, description: 'a test snippet')
      create(:snippet)

      ensure_elasticsearch_index!
    end

    options = { current_user: user }

    expect(described_class.elastic_search('home', options: options).total_count).to eq(1)
    expect(described_class.elastic_search('test snippet', options: options).total_count).to eq(1)
  end

  it "names elasticsearch queries" do
    described_class.elastic_search('*').total_count

    assert_named_queries('doc:is_a:snippet', 'snippet:match:search_terms', 'snippet:authorized')
  end

  it 'returns json with all needed elements' do
    snippet = create(:project_snippet)

    expected_hash = snippet.attributes.extract!(
      'id',
      'title',
      'created_at',
      'description',
      'updated_at',
      'state',
      'project_id',
      'author_id',
      'visibility_level'
    ).merge({
      'type' => snippet.es_type
    })

    expect(snippet.__elasticsearch__.as_indexed_json).to eq(expected_hash)
  end

  it 'uses same index for Snippet subclasses', :eager_load do
    Snippet.subclasses.each do |snippet_class|
      expect(snippet_class.index_name).to eq(Snippet.index_name)
      expect(snippet_class.document_type).to eq(Snippet.document_type)
      expect(snippet_class.__elasticsearch__.mappings.to_hash).to eq(Snippet.__elasticsearch__.mappings.to_hash)
    end
  end
end
