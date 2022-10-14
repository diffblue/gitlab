# frozen_string_literal: true

RSpec.shared_examples 'a redacted search results page' do |include_anonymous: true|
  let(:public_group) { create(:group, :public) }
  let(:public_restricted_project) { create(:project, :repository, :public, :wiki_repo, namespace: public_group, name: 'The Project') }
  let(:issue_access_level) { ProjectFeature::PRIVATE }
  let(:user_not_in_project) { create(:user) }

  before do
    stub_ee_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    stub_feature_flags(search_page_vertical_nav: false)

    Sidekiq::Testing.inline! do
      # Create a public project that the user is not member of.
      # And add some content to it.
      issue = create(:issue, project: public_restricted_project, title: 'The Issue')
      create(:note, project: public_restricted_project, noteable: issue, note: 'A note on issue')
      confidential_issue = create(:issue, :confidential, project: public_restricted_project, title: 'The Confidential Issue')
      create(:note, project: public_restricted_project, noteable: confidential_issue, note: 'A note on confidential issue')
      create(:milestone, project: public_restricted_project, title: 'The Milestone')
      create(:note_on_commit, project: public_restricted_project, note: 'A note on commit')
      create(:diff_note_on_commit, project: public_restricted_project, note: 'A note on diff on commit')
      merge_request = create(:merge_request_with_diffs, target_project: public_restricted_project, source_project: public_restricted_project, title: 'The Merge Request')
      create(:discussion_note_on_merge_request, noteable: merge_request, project: public_restricted_project, note: 'A note on discussion on merge request')
      create(:diff_note_on_merge_request, noteable: merge_request, project: public_restricted_project, note: 'A note on diff on merge request')
      create(:note_on_project_snippet, noteable: merge_request, project: public_restricted_project, note: 'A note on project snippet')

      # Add to the index while the data is still public
      ensure_elasticsearch_index!
    end

    # Then restrict access to that project but don't reindex so there is
    # stale authorization data in the index.
    public_restricted_project.project_feature.update!(
      issues_access_level: issue_access_level,
      merge_requests_access_level: ProjectFeature::PRIVATE,
      wiki_access_level: ProjectFeature::PRIVATE,
      snippets_access_level: ProjectFeature::PRIVATE,
      builds_access_level: ProjectFeature::PRIVATE,
      repository_access_level: ProjectFeature::PRIVATE
    )
  end

  it_behaves_like 'redacted search results page assertions', true
  it_behaves_like 'redacted search results page assertions', false if include_anonymous
end

# Only intended to be used in the above shared examples to avoid duplication of
# logged in vs. anonymous users
RSpec.shared_examples 'redacted search results page assertions' do |logged_in|
  context "when #{logged_in ? '' : 'not '}logged in" do
    before do
      sign_in(user_not_in_project) if logged_in
    end

    it 'redacts private features the user does not have access to' do
      visit search_path

      submit_search('*')

      # Projects scope is never available for searching within a project
      if has_search_scope?('Projects')
        select_search_scope('Projects')
        # Project is still public
        expect(page).to have_content('The Project')
      end

      # Issues scope is not available for search within a project when
      # issues are restricted
      if has_search_scope?('Issues')
        select_search_scope('Issues')
        # Project issues are restricted
        expect(page).not_to have_content('The Issue')
        expect(page).not_to have_content('The Confidential issue')
      end

      # Merge requests scope is not available for search within a project when
      # code is restricted
      if has_search_scope?('Merge requests')
        select_search_scope('Merge requests')
        # Project code is restricted
        expect(page).not_to have_content('The Merge Request')
      end

      # Milestones scope is not available for search within a project when
      # issues are restricted
      if has_search_scope?('Milestones')
        select_search_scope('Milestones')
        # Project issues are restricted
        expect(page).not_to have_content('The Milestone')
      end

      if has_search_scope?('Comments')
        select_search_scope('Comments')
        # All places where notes are posted are restricted
        expect(page).not_to have_content('A note on')
      end
    end

    context 'when issues are public' do
      let(:issue_access_level) { ProjectFeature::ENABLED }

      it 'redacts other private features' do
        visit search_path

        submit_search('*')

        # Projects scope is never available for searching within a project
        if has_search_scope?('Projects')
          select_search_scope('Projects')
          # Project is still public
          expect(page).to have_content('The Project')
        end

        select_search_scope('Issues')
        # Project issues are still public
        expect(page).to have_content('The Issue')
        expect(page).not_to have_content('The Confidential issue')

        # Merge requests scope is not available for search within a project when
        # code is restricted
        if has_search_scope?('Merge requests')
          select_search_scope('Merge requests')
          # Project code is restricted
          expect(page).not_to have_content('The Merge Request')
        end

        select_search_scope('Milestones')
        # Project issues are still public
        expect(page).to have_content('The Milestone')

        select_search_scope('Comments')
        # All places where notes are posted are restricted
        expect(page).to have_content('A note on issue')
        expect(page).to have_content('A note on', count: 1)
      end
    end
  end
end
