# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Search, factory_default: :keep, quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/347078',
                            feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:namespace) { create_default(:namespace).freeze }

  let(:project) { create(:project, :public, :repository, :wiki_repo, name: 'awesome project', group: group) }

  shared_examples 'response is correct' do |schema:, size: 1|
    it 'responds correctly' do
      expect(response).to have_gitlab_http_status(:ok)
      expect(response).to match_response_schema(schema)
      expect(response).to include_limited_pagination_headers
      expect(json_response.size).to eq(size)
    end
  end

  shared_examples 'pagination' do |scope:, search: '*'|
    it 'returns a different result for each page' do
      get api(endpoint, user), params: { scope: scope, search: search, page: 1, per_page: 1 }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response.count).to eq(1)

      first = json_response.first

      get api(endpoint, user), params: { scope: scope, search: search, page: 2, per_page: 1 }
      second = Gitlab::Json.parse(response.body).first

      expect(first).not_to eq(second)

      get api(endpoint, user), params: { scope: scope, search: search, per_page: 2 }

      expect(Gitlab::Json.parse(response.body).count).to eq(2)
    end
  end

  shared_examples 'orderable by created_at' do |scope:|
    it 'allows ordering results by created_at asc' do
      get api(endpoint, user), params: { scope: scope, search: '*', order_by: 'created_at', sort: 'asc' }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response.count).to be > 1

      created_ats = json_response.map { |r| Time.parse(r['created_at']) }

      expect(created_ats).to eq(created_ats.sort)
    end

    it 'allows ordering results by created_at desc' do
      get api(endpoint, user), params: { scope: scope, search: '*', order_by: 'created_at', sort: 'desc' }

      expect(response).to have_gitlab_http_status(:success)
      expect(json_response.count).to be > 1

      created_ats = json_response.map { |r| Time.parse(r['created_at']) }

      expect(created_ats).to eq(created_ats.sort.reverse)
    end
  end

  shared_examples 'elasticsearch disabled' do
    it 'returns 400 error for wiki_blobs, blobs and commits scope' do
      get api(endpoint, user), params: { scope: 'wiki_blobs', search: 'awesome' }

      expect(response).to have_gitlab_http_status(:bad_request)

      get api(endpoint, user), params: { scope: 'blobs', search: 'monitors' }

      expect(response).to have_gitlab_http_status(:bad_request)

      get api(endpoint, user), params: { scope: 'commits', search: 'folder' }

      expect(response).to have_gitlab_http_status(:bad_request)
    end
  end

  shared_examples 'elasticsearch enabled' do |level:|
    context 'for merge_requests scope', :sidekiq_inline do
      before do
        create_list(:merge_request, 3, :unique_branches, source_project: project, author: create(:user), milestone: create(:milestone, project: project), labels: [create(:label)])
        ensure_elasticsearch_index!
      end

      it_behaves_like 'pagination', scope: 'merge_requests'
      it_behaves_like 'orderable by created_at', scope: 'merge_requests'

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { get api(endpoint, user), params: { scope: 'merge_requests', search: '*' } }
        create_list(:merge_request, 3, :unique_branches, source_project: project, author: create(:user), milestone: create(:milestone, project: project), labels: [create(:label)])
        ensure_elasticsearch_index!

        expect { get api(endpoint, user), params: { scope: 'merge_requests', search: '*' } }.not_to exceed_query_limit(control)
      end
    end

    context 'for wiki_blobs scope', :sidekiq_inline do
      before do
        wiki = create(:project_wiki, project: project)
        create(:wiki_page, wiki: wiki, title: 'home', content: "Awesome page")
        create(:wiki_page, wiki: wiki, title: 'other', content: "Another page")

        project.wiki.index_wiki_blobs
        ensure_elasticsearch_index!
      end

      it_behaves_like 'response is correct', schema: 'public_api/v4/blobs' do
        before do
          get api(endpoint, user), params: { scope: 'wiki_blobs', search: 'awesome' }
        end
      end

      it_behaves_like 'pagination', scope: 'wiki_blobs'
    end

    context 'for commits and blobs', :sidekiq_inline do
      before do
        project.repository.index_commits_and_blobs
        ensure_elasticsearch_index!
      end

      context 'for commits scope' do
        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details', size: 2 do
          before do
            get api(endpoint, user), params: { scope: 'commits', search: 'folder' }
          end
        end

        it_behaves_like 'pagination', scope: 'commits'

        it 'avoids N+1 queries' do
          control = ActiveRecord::QueryRecorder.new { get api(endpoint, user), params: { scope: 'commits', search: 'folder' } }

          project_2 = create(:project, :public, :repository, :wiki_repo, group: group, name: 'awesome project 2')
          project_2.repository.index_commits_and_blobs
          3.times do |i|
            commit_sha = project.repository.create_file(user, i.to_s, "folder #{i}", message: "committing folder #{i}", branch_name: 'master')
            project.repository.commit(commit_sha)
          end
          project.repository.index_commits_and_blobs

          ensure_elasticsearch_index!

          # N+1 queries still exist (ci_pipelines)
          expect { get api(endpoint, user), params: { scope: 'commits', search: 'folder' } }.not_to exceed_query_limit(control).with_threshold(5)
          # support global, group, and project search results expected counts
          expected_count = level == :project ? 5 : 7
          expect(json_response.count).to be expected_count
        end
      end

      context 'for blobs scope' do
        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs' do
          before do
            get api(endpoint, user), params: { scope: 'blobs', search: 'folder' }
          end
        end

        it_behaves_like 'pagination', scope: 'blobs'

        it 'avoids N+1 queries' do
          control = ActiveRecord::QueryRecorder.new { get api(endpoint, user), params: { scope: 'blobs', search: 'Issue team' } }

          project_2 = create(:project, :public, :repository, :wiki_repo, group: group, name: 'awesome project 2')
          project_2.repository.index_commits_and_blobs
          3.times do |i|
            commit_sha = project.repository.create_file(user, i.to_s, "Issue team #{i}", message: i.to_s, branch_name: 'master')
            project.repository.commit(commit_sha)
          end

          project.repository.index_commits_and_blobs
          ensure_elasticsearch_index!

          expect { get api(endpoint, user), params: { scope: 'blobs', search: 'Issue team' } }.not_to exceed_query_limit(control)
          # support global, group, and project search results expected counts
          expected_count = level == :project ? 6 : 9
          expect(json_response.count).to be expected_count
        end

        context 'filters' do
          def results_filenames
            json_response.map { |h| h['filename'] }.compact
          end

          def results_paths
            json_response.map { |h| h['path'] }.compact
          end

          context 'with an including filter' do
            it 'by filename' do
              get api("/projects/#{project.id}/search", user), params: { scope: 'blobs', search: 'mon* filename:PROCESS.md' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response.size).to eq(1)
              expect(results_filenames).to all(match(%r{PROCESS.md$}))
            end

            it 'by path' do
              get api("/projects/#{project.id}/search", user), params: { scope: 'blobs', search: 'mon* path:markdown' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response.size).to eq(1)
              expect(results_paths).to all(match(%r{^files/markdown/}))
            end

            it 'by extension' do
              get api("/projects/#{project.id}/search", user), params: { scope: 'blobs', search: 'mon* extension:md' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(json_response.size).to eq(3)
              expect(results_filenames).to all(match(%r{.*.md$}))
            end
          end

          context 'with an excluding filter' do
            it 'by filename' do
              get api(endpoint, user), params: { scope: 'blobs', search: '* -filename:PROCESS.md' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(results_filenames).not_to include('PROCESS.md')
              expect(json_response.size).to eq(20)
            end

            it 'by path' do
              get api(endpoint, user), params: { scope: 'blobs', search: '* -path:files/markdown' }

              expect(response).to have_gitlab_http_status(:ok)
              expect(results_paths).not_to include(a_string_matching(%r{^files/markdown/}))
              expect(json_response.size).to eq(20)
            end

            it 'by extension' do
              get api(endpoint, user), params: { scope: 'blobs', search: '* -extension:md' }

              expect(response).to have_gitlab_http_status(:ok)

              expect(results_filenames).not_to include(a_string_matching(%r{.*.md$}))
              expect(json_response.size).to eq(20)
            end
          end
        end
      end
    end

    context 'for issues scope', :sidekiq_inline do
      before do
        create_list(:issue, 2, project: project)
        ensure_elasticsearch_index!
      end

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { get api(endpoint, user), params: { scope: 'issues', search: '*' } }

        create_list(:issue, 2, project: project)
        create_list(:issue, 2, project: create(:project, group: group))
        create_list(:issue, 2)

        ensure_elasticsearch_index!

        expect { get api(endpoint, user), params: { scope: 'issues', search: '*' } }.not_to exceed_query_limit(control)
      end

      it_behaves_like 'pagination', scope: 'issues'
      it_behaves_like 'orderable by created_at', scope: 'issues'
    end

    unless level == :project
      context 'for projects scope', :sidekiq_inline do
        before do
          project
          create(:project, :public, name: 'second project', group: group)

          ensure_elasticsearch_index!
        end

        it_behaves_like 'pagination', scope: 'projects'

        it 'avoids N+1 queries' do
          control = ActiveRecord::QueryRecorder.new { get api(endpoint, user), params: { scope: 'projects', search: '*' } }
          create_list(:project, 3, :public, group: group)
          create_list(:project, 4, :public)

          ensure_elasticsearch_index!

          # Some N+1 queries still exist
          expect { get api(endpoint, user), params: { scope: 'projects', search: '*' } }.not_to exceed_query_limit(control).with_threshold(4)
        end
      end
    end

    context 'for milestones scope', :sidekiq_inline do
      before do
        create_list(:milestone, 2, project: project)

        ensure_elasticsearch_index!
      end

      it_behaves_like 'pagination', scope: 'milestones'

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { get api(endpoint, user), params: { scope: 'milestones', search: '*' } }
        create_list(:milestone, 3, project: project)
        create_list(:milestone, 2, project: create(:project, :public))

        ensure_elasticsearch_index!

        expect { get api(endpoint, user), params: { scope: 'milestones', search: '*' } }.not_to exceed_query_limit(control)
      end
    end

    context 'for users scope', :sidekiq_might_not_need_inline do
      before do
        create_list(:user, 2).each do |user|
          project.add_developer(user)
          group.add_developer(user)
        end
      end

      it_behaves_like 'pagination', scope: 'users', search: ''

      it 'avoids N+1 queries' do
        control = ActiveRecord::QueryRecorder.new { get api(endpoint, user), params: { scope: 'users', search: '*' } }
        create_list(:user, 2).each do |user|
          project.add_developer(user)
          group.add_developer(user)
        end

        ensure_elasticsearch_index!

        expect { get api(endpoint, user), params: { scope: 'users', search: '*' } }.not_to exceed_query_limit(control)
      end
    end

    context 'for notes scope', :sidekiq_inline do
      before do
        create(:note_on_merge_request, project: project, note: 'awesome note')
        mr = create(:merge_request, source_project: project, target_branch: 'another_branch')
        create(:note, project: project, noteable: mr, note: 'another note')

        ensure_elasticsearch_index!
      end

      it_behaves_like 'pagination', scope: 'notes'
    end

    if level == :global
      context 'for snippet_titles scope', :sidekiq_inline do
        before do
          create_list(:snippet, 2, :public, title: 'Some code', content: 'Check it out')

          ensure_elasticsearch_index!
        end

        it_behaves_like 'pagination', scope: 'snippet_titles'
      end
    end
  end

  describe 'GET /search' do
    let(:endpoint) { '/search' }

    context 'with correct params' do
      context 'when elasticsearch is disabled' do
        it_behaves_like 'elasticsearch disabled'

        it 'sets global search information for logging' do
          expect(Gitlab::Instrumentation::GlobalSearchApi).to receive(:set_information).with(
            type: 'basic',
            level: 'global',
            scope: 'issues',
            search_duration_s: a_kind_of(Numeric)
          )

          get api(endpoint, user), params: { scope: 'issues', search: 'john doe' }
        end
      end

      context 'when elasticsearch is enabled', :elastic, :clean_gitlab_redis_shared_state do
        before do
          stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
        end

        context 'when elasticsearch_limit_indexing is on' do
          before do
            stub_ee_application_setting(elasticsearch_limit_indexing: true)
          end

          context 'and namespace is indexed' do
            before do
              create :elasticsearch_indexed_namespace, namespace: group
            end

            it_behaves_like 'elasticsearch enabled', level: :global
          end
        end

        context 'when elasticsearch_limit_indexing off' do
          before do
            stub_ee_application_setting(elasticsearch_limit_indexing: false)
          end

          it_behaves_like 'elasticsearch enabled', level: :global
        end

        it 'sets global search information for logging' do
          expect(Gitlab::Instrumentation::GlobalSearchApi).to receive(:set_information).with(
            type: 'advanced',
            level: 'global',
            scope: 'issues',
            search_duration_s: a_kind_of(Numeric)
          )

          get api(endpoint, user), params: { scope: 'issues', search: 'john doe' }
        end
      end
    end
  end

  describe "GET /groups/:id/-/search" do
    let(:endpoint) { "/groups/#{group.id}/-/search" }

    context 'with correct params' do
      context 'when elasticsearch is disabled' do
        it_behaves_like 'elasticsearch disabled'
      end

      context 'when elasticsearch is enabled', :elastic, :clean_gitlab_redis_shared_state do
        before do
          stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
        end

        context 'when elasticsearch_limit_indexing is on' do
          before do
            stub_ee_application_setting(elasticsearch_limit_indexing: true)
          end

          context 'when the namespace is indexed' do
            before do
              create :elasticsearch_indexed_namespace, namespace: group
            end

            it_behaves_like 'elasticsearch enabled', level: :group
          end

          context 'when the namespace is not indexed' do
            it_behaves_like 'elasticsearch disabled'
          end
        end

        context 'when elasticsearch_limit_indexing off' do
          before do
            stub_ee_application_setting(elasticsearch_limit_indexing: false)
          end

          it_behaves_like 'elasticsearch enabled', level: :group
        end
      end
    end
  end

  describe "GET /projects/:id/-/search" do
    let(:endpoint) { "/projects/#{project.id}/-/search" }

    shared_examples_for 'search enabled' do
      context 'for wiki_blobs scope' do
        before do
          wiki = create(:project_wiki, project: project)
          create(:wiki_page, wiki: wiki, title: 'home', content: "Awesome page")

          get api(endpoint, user), params: { scope: 'wiki_blobs', search: 'awesome' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs'
      end

      context 'for commits scope' do
        before do
          get api(endpoint, user), params: { scope: 'commits', search: 'folder' }
        end

        it_behaves_like 'response is correct', schema: 'public_api/v4/commits_details', size: 2
      end

      context 'for blobs scope' do
        it_behaves_like 'response is correct', schema: 'public_api/v4/blobs', size: 2 do
          before do
            get api(endpoint, user), params: { scope: 'blobs', search: 'monitors' }
          end
        end

        context 'filters' do
          it 'by filename' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'mon filename:PROCESS.md' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(2)
            expect(json_response.first['path']).to eq('PROCESS.md')
            expect(json_response.first['filename']).to eq('PROCESS.md')
          end

          it 'by path' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'mon path:files/markdown' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(8)
          end

          it 'by extension' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'mon extension:md' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(11)
          end

          it 'by ref' do
            get api(endpoint, user), params: { scope: 'blobs', search: 'This file is used in tests for ci_environments_status', ref: 'pages-deploy' }

            expect(response).to have_gitlab_http_status(:ok)
            expect(json_response.size).to eq(1)
          end
        end
      end
    end

    context 'with correct params' do
      context 'when elasticsearch is disabled' do
        it_behaves_like 'search enabled'
      end

      context 'when elasticsearch is enabled', :elastic, :clean_gitlab_redis_shared_state do
        before do
          stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
        end

        context 'when elasticsearch_limit_indexing is on' do
          before do
            stub_ee_application_setting(elasticsearch_limit_indexing: true)
          end

          context 'when the project is indexed' do
            before do
              create :elasticsearch_indexed_project, project: project
            end

            it_behaves_like 'elasticsearch enabled', level: :project
          end

          context 'when the project is not indexed' do
            it_behaves_like 'search enabled'
          end
        end

        context 'when elasticsearch_limit_indexing off' do
          before do
            stub_ee_application_setting(elasticsearch_limit_indexing: false)
          end

          it_behaves_like 'elasticsearch enabled', level: :project
        end
      end
    end
  end
end
