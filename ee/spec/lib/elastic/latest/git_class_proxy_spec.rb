# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::GitClassProxy, :elastic, :sidekiq_inline, feature_category: :global_search do
  let(:project) { create(:project, :public, :repository) }
  let(:included_class) { Elastic::Latest::RepositoryClassProxy }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.repository.index_commits_and_blobs
    ensure_elasticsearch_index!
  end

  subject { included_class.new(project.repository) }

  describe '#elastic_search' do
    context 'if type is wiki_blob' do
      let_it_be(:wiki_project) { create(:project, :wiki_repo, visibility_level: 0, wiki_access_level: 0) }

      context 'if migrate_wikis_to_separate_index is not finished' do
        before do
          set_elasticsearch_migration_to(:migrate_wikis_to_separate_index, including: false)
          wiki_project.wiki.create_page('home_page', 'Bla bla term')
          wiki_project.wiki.index_wiki_blobs
          ensure_elasticsearch_index!
        end

        it 'fetches the results from the main index' do
          results = subject.elastic_search('Bla', type: 'wiki_blob')[:wiki_blobs][:results]

          expect(results.total).to eq 1
          expect(results.first._index).to match(/#{es_helper.target_name}/)
        end
      end

      context 'if migrate_wikis_to_separate_index is finished' do
        before do
          set_elasticsearch_migration_to(:migrate_wikis_to_separate_index, including: true)
          wiki_project.wiki.create_page('home_page', 'Bla bla term')
          wiki_project.wiki.index_wiki_blobs
          ensure_elasticsearch_index!
        end

        it 'fetches the results from the new separate index' do
          results = subject.elastic_search('Bla', type: 'wiki_blob')[:wiki_blobs][:results]

          expect(results.total).to eq 1
          expect(results.first._index).to match(/#{es_helper.target_name}-wikis/)
        end
      end
    end
  end

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

    context 'with filters in the query' do
      let(:query) { 'def extension:rb path:files/ruby' }

      it 'returns matching results', :sidekiq_inline do
        results = subject.elastic_search_as_found_blob(query)
        paths = results.map(&:path)

        expect(paths).to contain_exactly('files/ruby/regex.rb', 'files/ruby/popen.rb', 'files/ruby/version_info.rb')
      end

      context 'when part of the path is used ' do
        let(:query) { 'def extension:rb path:files' }

        it 'returns the same results as when the full path is used', :sidekiq_inline do
          results = subject.elastic_search_as_found_blob(query)
          paths = results.map(&:path)

          expect(paths).to contain_exactly('files/ruby/regex.rb', 'files/ruby/popen.rb', 'files/ruby/version_info.rb')
        end

        context 'when the path query is in the middle of the file path' do
          let(:query) { 'def extension:rb path:ruby' }

          it 'returns the same results as when the full path is used', :sidekiq_inline do
            results = subject.elastic_search_as_found_blob(query)
            paths = results.map(&:path)

            expect(paths).to contain_exactly('files/ruby/regex.rb', 'files/ruby/popen.rb', 'files/ruby/version_info.rb')
          end
        end
      end
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
      expect(result.first.buckets.first[:key]).to eq('Markdown')
      expect(result.first.buckets.first[:count]).to eq(2)
    end
  end

  it "names elasticsearch queries" do
    subject.elastic_search_as_found_blob('*')

    assert_named_queries('doc:is_a:blob',
                         'blob:match:search_terms')
  end

  context 'when backfilling migration is complete' do
    let_it_be(:user) { create(:user) }

    it 'does not use the traversal_id filter when project_ids are passed' do
      expect(Namespace).not_to receive(:find)
      subject.elastic_search_as_found_blob('*', options: { current_user: user, project_ids: [1, 2] })
    end

    it 'does not use the traversal_id filter when group_ids are not passed' do
      expect(Namespace).not_to receive(:find)
      subject.elastic_search_as_found_blob('*', options: { current_user: user })
    end

    it 'uses the traversal_id filter' do
      expect(Namespace).to receive(:find).once.and_call_original
      subject.elastic_search_as_found_blob('*', options: { current_user: user, group_ids: [1] })
    end
  end
end
