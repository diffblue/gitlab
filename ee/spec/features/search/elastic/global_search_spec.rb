# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Global elastic search', :elastic, :js, :sidekiq_inline, :disable_rate_limiter,
feature_category: :global_search do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project, :repository, :wiki_repo, namespace: user.namespace) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)

    project.add_maintainer(user)
    sign_in(user)
  end

  describe 'I search through the issues and I see pagination' do
    before do
      create_list(:issue, 21, project: project, title: 'initial')

      ensure_elasticsearch_index!
    end

    it "has a pagination" do
      visit dashboard_projects_path

      submit_search('initial')
      select_search_scope('Issues')

      expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
    end
  end

  describe 'I search through the notes and I see pagination' do
    before do
      issue = create(:issue, project: project, title: 'initial')
      create_list(:note, 21, noteable: issue, project: project, note: 'foo')

      ensure_elasticsearch_index!
    end

    it "has a pagination" do
      visit dashboard_projects_path

      submit_search('foo')
      select_search_scope('Comments')

      expect(page).to have_selector('.gl-pagination .js-pagination-page', count: 2)
    end
  end

  describe 'I search through the blobs' do
    before do
      project.repository.index_commits_and_blobs

      ensure_elasticsearch_index!
    end

    it "finds files" do
      visit dashboard_projects_path

      submit_search('application.js')
      select_search_scope('Code')

      expect(page).to have_selector('.file-content .code')
      expect(page).to have_selector("span.line[lang='javascript']")
      expect(page).to have_button('Copy file path')
    end

    it 'ignores nonexistent projects from stale index' do
      stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
      project_2 = create(:project, :repository, :wiki_repo)

      project_2.repository.create_file(
        user,
        'thing.txt',
        ' function application.js ',
        message: 'supercalifragilisticexpialidocious',
        branch_name: 'master')

      project_2.repository.index_commits_and_blobs

      ensure_elasticsearch_index!

      project_2.destroy!

      visit dashboard_projects_path

      submit_search('application.js')

      expect(page).not_to have_content 'supercalifragilisticexpialidocious'
    end
  end

  describe 'I search through the wiki blobs' do
    before do
      project.wiki.create_page('test.md', '# term')
      project.wiki.index_wiki_blobs

      ensure_elasticsearch_index!
    end

    it "finds wiki pages" do
      visit dashboard_projects_path

      submit_search('term')
      select_search_scope('Wiki')

      expect(page).to have_selector('.search-result-row .description', text: 'term')
      expect(page).to have_link('test')
    end
  end

  describe 'I search through the commits' do
    before do
      project.repository.index_commits_and_blobs
      ensure_elasticsearch_index!
    end

    it "finds commits" do
      visit dashboard_projects_path

      submit_search('add')
      select_search_scope('Commits')

      expect(page).to have_selector('.commit-list > .commit')
      expect(page).to have_text project.full_name
    end

    it 'shows proper page 2 results' do
      visit dashboard_projects_path

      submit_search('add')
      select_search_scope('Commits')

      expected_message = "Merge branch 'tree_helper_spec' into 'master'"

      expect(page).not_to have_content(expected_message)

      click_link 'Next'

      expect(page).to have_content(expected_message)
    end
  end

  describe 'I search globally' do
    before do
      create(:issue, project: project, title: 'project issue')
      ensure_elasticsearch_index!

      visit dashboard_projects_path

      submit_search('project')
    end

    it 'displays result counts for all categories' do
      expect(page).to have_content('Projects 1')
      expect(page).to have_content('Issues 1')
      expect(page).to have_content('Merge requests 0')
      expect(page).to have_content('Milestones 0')
      expect(page).to have_content('Comments 0')
      expect(page).to have_content('Code 0')
      expect(page).to have_content('Commits 0')
      expect(page).to have_content('Wiki 0')
      expect(page).to have_content('Users 0')
    end
  end
end

RSpec.describe 'Global elastic search redactions', feature_category: :global_search do
  context 'when block_anonymous_global_searches is disabled' do
    before do
      stub_feature_flags(block_anonymous_global_searches: false)
    end

    it_behaves_like 'a redacted search results page' do
      let(:search_path) { explore_root_path }
    end
  end

  context 'when block_anonymous_global_searches is enabled' do
    it_behaves_like 'a redacted search results page', include_anonymous: false do
      let(:search_path) { explore_root_path }
    end
  end
end
