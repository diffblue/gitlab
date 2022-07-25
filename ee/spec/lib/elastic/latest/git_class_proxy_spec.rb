# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::GitClassProxy, :elastic do
  let(:project) { create(:project, :public, :repository) }
  let(:included_class) { Elastic::Latest::RepositoryClassProxy }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.repository.index_commits_and_blobs
    ensure_elasticsearch_index!
  end

  subject { included_class.new(project.repository) }

  describe '#elastic_search_as_found_blob' do
    it 'returns FoundBlob', :sidekiq_inline do
      results = subject.elastic_search_as_found_blob('def popen')

      expect(results).not_to be_empty
      expect(results).to all(be_a(Gitlab::Search::FoundBlob))

      result = results.first

      expect(result.ref).to eq('b83d6e391c22777fca1ed3012fce84f633d7fed0')
      expect(result.path).to eq('files/ruby/popen.rb')
      expect(result.startline).to eq(2)
      expect(result.data).to include('Popen')
      expect(result.project).to eq(project)
    end
  end

  describe '#blob_aggregations' do
    let(:user) { create(:user) }
    let(:options) do
      {
        current_user: user,
        project_ids: [project.id],
        public_and_internal_projects: false,
        order_by: nil,
        sort: nil
      }
    end

    before do
      project.add_developer(user)
    end

    it 'returns aggregations', :sidekiq_inline do
      result = subject.blob_aggregations('This guide details how contribute to GitLab', options)

      expect(result.first.name).to eq('language')
      expect(result.first.buckets.first[:key]).to eq({ 'language' => 'Markdown' })
      expect(result.first.buckets.first[:count]).to eq(2)
    end

    context 'when search_blobs_language_aggregation feature flag is disabled' do
      before do
        stub_feature_flags(search_blobs_language_aggregation: false)
      end

      it 'returns empty array' do
        result = subject.blob_aggregations('This guide details how contribute to GitLab', options)

        expect(result).to match_array([])
      end
    end
  end

  it "names elasticsearch queries" do
    subject.elastic_search_as_found_blob('*')

    assert_named_queries('doc:is_a:blob',
                         'blob:match:search_terms')
  end
end
