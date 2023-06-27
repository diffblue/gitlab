# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::Latest::GitClassProxy, :elastic, :sidekiq_inline, feature_category: :global_search do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :repository, group: group) }

  let(:included_class) { Elastic::Latest::RepositoryClassProxy }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    ::Elastic::ProcessBookkeepingService.track!(project)
    project.repository.index_commits_and_blobs
    ensure_elasticsearch_index!
  end

  subject { included_class.new(project.repository.class) }

  describe '#elastic_search' do
    let_it_be(:user) { create(:user) }

    context 'when type is wiki_blob' do
      let_it_be(:project2) { create(:project, :public, group: group) }
      let_it_be(:project2_wiki) { create(:project_wiki, project: project2, user: user) }
      let(:included_class) { Elastic::Latest::WikiClassProxy }

      subject { included_class.new(project.wiki.class, use_separate_indices: ProjectWiki.use_separate_indices?) }

      context 'when performing a global search' do
        let(:search_options) do
          {
            current_user: user,
            public_and_internal_projects: true,
            order_by: nil,
            sort: nil
          }
        end

        it 'uses the correct elasticsearch query' do
          subject.elastic_search('*', type: 'wiki_blob', options: search_options)
          assert_named_queries('doc:is_a:wiki_blob', 'blob:authorized:project', 'blob:match:search_terms')
        end
      end

      context 'when performing a group search' do
        let(:search_options) do
          {
            current_user: user,
            project_ids: [project.id, project2.id],
            group_ids: [project.namespace.id],
            public_and_internal_projects: false,
            order_by: nil,
            sort: nil
          }
        end

        it 'uses the correct elasticsearch query' do
          subject.elastic_search('*', type: 'wiki_blob', options: search_options)
          assert_named_queries('doc:is_a:wiki_blob', 'blob:authorized:project', 'blob:match:search_terms')
        end

        context 'when user is authorized for the namespace' do
          it 'uses the correct elasticsearch query' do
            group.add_reporter(user)

            subject.elastic_search('*', type: 'wiki_blob', options: search_options)
            assert_named_queries('doc:is_a:wiki_blob', 'blob:match:search_terms', 'blob:authorized:reject_projects',
              'blob:authorized:namespace:ancestry_filter:descendants')
          end
        end

        context 'when performing a project search' do
          let(:search_options) do
            {
              current_user: user,
              project_ids: [project.id],
              public_and_internal_projects: false,
              order_by: nil,
              sort: nil,
              repository_id: project.id
            }
          end

          it 'uses the correct elasticsearch query' do
            subject.elastic_search('*', type: 'wiki_blob', options: search_options)
            assert_named_queries('doc:is_a:wiki_blob', 'blob:authorized:project', 'blob:match:search_terms',
              'blob:related:repositories')
          end
        end
      end

      context 'if migrate_wikis_to_separate_index is not finished' do
        before do
          set_elasticsearch_migration_to(:migrate_wikis_to_separate_index, including: false)
          project2_wiki.create_page('home_page', 'Bla bla term')
          project2_wiki.index_wiki_blobs
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
          project2_wiki.create_page('home_page', 'Bla bla term')
          project2_wiki.index_wiki_blobs
          ensure_elasticsearch_index!
        end

        it 'fetches the results from the new separate index' do
          results = subject.elastic_search('Bla', type: 'wiki_blob')[:wiki_blobs][:results]

          expect(results.total).to eq 1
          expect(results.first._index).to match(/#{es_helper.target_name}-wikis/)
        end
      end
    end

    context 'when type is blob' do
      context 'when performing a global search' do
        let(:search_options) do
          {
            current_user: user,
            public_and_internal_projects: true,
            order_by: nil,
            sort: nil
          }
        end

        it 'uses the correct elasticsearch query' do
          subject.elastic_search('*', type: 'blob', options: search_options)
          assert_named_queries('doc:is_a:blob', 'blob:authorized:project', 'blob:match:search_terms')
        end

        context 'when backfill_project_permissions_in_blobs migration is not finished' do
          before do
            set_elasticsearch_migration_to(:backfill_project_permissions_in_blobs, including: false)
          end

          it 'uses the correct elasticsearch query' do
            subject.elastic_search('*', type: 'blob', options: search_options)
            assert_named_queries('doc:is_a:blob', 'blob:authorized:project:parent', 'blob:match:search_terms')
          end
        end
      end

      context 'when performing a group search' do
        let(:search_options) do
          {
            current_user: user,
            project_ids: [project.id],
            group_ids: [project.namespace.id],
            public_and_internal_projects: false,
            order_by: nil,
            sort: nil
          }
        end

        it 'uses the correct elasticsearch query' do
          subject.elastic_search('*', type: 'blob', options: search_options)
          assert_named_queries('doc:is_a:blob', 'blob:authorized:project', 'blob:match:search_terms')
        end

        context 'when user is authorized for the namespace' do
          it 'uses the correct elasticsearch query' do
            group.add_reporter(user)

            subject.elastic_search('*', type: 'blob', options: search_options)
            assert_named_queries('doc:is_a:blob', 'blob:match:search_terms', 'blob:authorized:reject_projects',
              'blob:authorized:namespace:ancestry_filter:descendants')
          end
        end

        context 'when performing a project search' do
          let(:search_options) do
            {
              current_user: user,
              project_ids: [project.id],
              public_and_internal_projects: false,
              order_by: nil,
              sort: nil,
              repository_id: project.id
            }
          end

          it 'uses the correct elasticsearch query' do
            subject.elastic_search('*', type: 'blob', options: search_options)
            assert_named_queries('doc:is_a:blob', 'blob:authorized:project',
              'blob:match:search_terms', 'blob:related:repositories')
          end
        end
      end
    end

    context 'when type is commit' do
      context 'when performing a global search' do
        let(:search_options) do
          {
            current_user: user,
            public_and_internal_projects: true,
            order_by: nil,
            sort: nil
          }
        end

        it 'uses the correct elasticsearch query' do
          subject.elastic_search('*', type: 'commit', options: search_options)
          assert_named_queries('doc:is_a:commit', 'commit:authorized:project', 'commit:match:search_terms')
        end
      end

      context 'when performing a group search' do
        let(:search_options) do
          {
            current_user: user,
            project_ids: [project.id],
            group_ids: [project.namespace.id],
            public_and_internal_projects: false,
            order_by: nil,
            sort: nil
          }
        end

        it 'uses the correct elasticsearch query' do
          subject.elastic_search('*', type: 'commit', options: search_options)
          assert_named_queries('doc:is_a:commit', 'commit:authorized:project', 'commit:match:search_terms')
        end

        context 'when user is authorized for the namespace' do
          it 'uses the correct elasticsearch query' do
            group.add_reporter(user)

            subject.elastic_search('*', type: 'commit', options: search_options)
            assert_named_queries('doc:is_a:commit', 'commit:authorized:project', 'commit:match:search_terms')
          end
        end

        context 'when performing a project search' do
          let(:search_options) do
            {
              current_user: user,
              project_ids: [project.id],
              public_and_internal_projects: false,
              order_by: nil,
              sort: nil,
              repository_id: project.id
            }
          end

          it 'uses the correct elasticsearch query' do
            subject.elastic_search('*', type: 'commit', options: search_options)
            assert_named_queries('doc:is_a:commit', 'commit:authorized:project',
              'commit:match:search_terms', 'commit:related:repositories')
          end
        end

        context 'when requesting highlighting' do
          let(:search_options) do
            {
              current_user: user,
              project_ids: [project.id],
              public_and_internal_projects: false,
              order_by: nil,
              sort: nil,
              repository_id: project.id,
              highlight: true
            }
          end

          it 'returns highlight in the results' do
            results = subject.elastic_search('Add', type: 'commit', options: search_options)
            expect(results[:commits][:results].results.first.keys).to include('highlight')
          end
        end
      end
    end

    context 'when type is all' do
      context 'when performing a global search' do
        let(:search_options) do
          {
            current_user: user,
            public_and_internal_projects: true,
            order_by: nil,
            sort: nil
          }
        end

        it 'returns results for all three types' do
          result = subject.elastic_search('*', type: 'all', options: search_options)
          expect(result.keys).to match_array([:wiki_blobs, :blobs, :commits])
        end
      end

      context 'when performing a group search' do
        let(:search_options) do
          {
            current_user: user,
            project_ids: [project.id],
            group_ids: [project.namespace.id],
            public_and_internal_projects: false,
            order_by: nil,
            sort: nil
          }
        end

        it 'returns results for all three types' do
          result = subject.elastic_search('*', type: 'all', options: search_options)
          expect(result.keys).to match_array([:wiki_blobs, :blobs, :commits])
        end
      end

      context 'when performing a project search' do
        let(:search_options) do
          {
            current_user: user,
            project_ids: [project.id],
            public_and_internal_projects: false,
            order_by: nil,
            sort: nil,
            repository_id: project.id
          }
        end

        it 'returns results for all three types' do
          result = subject.elastic_search('*', type: 'all', options: search_options)
          expect(result.keys).to match_array([:wiki_blobs, :blobs, :commits])
        end
      end
    end
  end

  describe '#elastic_search_as_found_blob', :aggregate_failures do
    it 'returns FoundBlob' do
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

      it 'returns matching results' do
        results = subject.elastic_search_as_found_blob(query)
        paths = results.map(&:path)

        expect(paths).to contain_exactly('files/ruby/regex.rb',
          'files/ruby/popen.rb',
          'files/ruby/version_info.rb')
      end

      context 'when part of the path is used ' do
        let(:query) { 'def extension:rb path:files' }

        it 'returns the same results as when the full path is used' do
          results = subject.elastic_search_as_found_blob(query)
          paths = results.map(&:path)

          expect(paths).to contain_exactly('files/ruby/regex.rb',
            'files/ruby/popen.rb',
            'files/ruby/version_info.rb')
        end

        context 'when the path query is in the middle of the file path' do
          let(:query) { 'def extension:rb path:ruby' }

          it 'returns the same results as when the full path is used' do
            results = subject.elastic_search_as_found_blob(query)
            paths = results.map(&:path)

            expect(paths).to contain_exactly('files/ruby/regex.rb',
              'files/ruby/popen.rb',
              'files/ruby/version_info.rb')
          end
        end
      end
    end
  end

  describe '#blob_aggregations' do
    let_it_be(:user) { create(:user) }

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

    it 'returns aggregations' do
      result = subject.blob_aggregations('This guide details how contribute to GitLab', options)

      expect(result.first.name).to eq('language')
      expect(result.first.buckets.first[:key]).to eq('Markdown')
      expect(result.first.buckets.first[:count]).to eq(2)
    end

    it 'assert names queries for global blob search when migration is complete' do
      search_options = {
        current_user: user,
        public_and_internal_projects: true,
        order_by: nil,
        sort: nil
      }
      subject.blob_aggregations('*', search_options)
      assert_named_queries('doc:is_a:blob', 'blob:authorized:project',
        'blob:match:search_terms')
    end

    it 'assert names queries for global blob search when migration is not complete' do
      search_options = {
        current_user: user,
        public_and_internal_projects: true,
        order_by: nil,
        sort: nil
      }
      set_elasticsearch_migration_to(:backfill_project_permissions_in_blobs, including: false)

      subject.blob_aggregations('*', search_options)
      assert_named_queries('doc:is_a:blob', 'blob:authorized:project:parent',
        'blob:match:search_terms')
    end

    it 'assert names queries for group blob search' do
      group_search_options = {
        current_user: user,
        project_ids: [project.id],
        group_ids: [project.namespace.id],
        public_and_internal_projects: false,
        order_by: nil,
        sort: nil
      }
      subject.blob_aggregations('*', group_search_options)
      assert_named_queries('doc:is_a:blob', 'blob:authorized:reject_projects', 'blob:match:search_terms',
        'blob:authorized:namespace:ancestry_filter:descendants')
    end

    it 'assert names queries for project blob search' do
      project_search_options = {
        current_user: user,
        project_ids: [project.id],
        public_and_internal_projects: false,
        order_by: nil,
        sort: nil
      }
      subject.blob_aggregations('*', project_search_options)
      assert_named_queries('doc:is_a:blob', 'blob:authorized:project', 'blob:match:search_terms')
    end
  end

  it "names elasticsearch queries" do
    subject.elastic_search_as_found_blob('*')

    assert_named_queries('doc:is_a:blob', 'blob:match:search_terms')
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
