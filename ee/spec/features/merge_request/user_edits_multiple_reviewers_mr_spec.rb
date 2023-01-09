# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Merge request > User edits MR with multiple reviewers', feature_category: :code_review_workflow do
  include_context 'merge request edit context'

  before do
    stub_licensed_features(multiple_merge_request_reviewers: true)
  end

  it_behaves_like 'multiple reviewers merge request', 'updates', 'Save changes'

  context 'user approval rules', :js do
    let(:rule_name) { 'some-custom-rule' }
    let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request, users: [user], name: rule_name, approvals_required: 1) }

    it 'is not shown in assignee dropdown' do
      find('.js-assignee-search').click
      wait_for_requests

      page.within '.dropdown-menu-assignee' do
        expect(page).not_to have_content(rule_name)
      end
    end

    it 'is shown in reviewer dropdown' do
      find('.js-reviewer-search').click
      wait_for_requests

      page.within '.dropdown-menu-reviewer' do
        expect(page).to have_content(rule_name)
      end
    end

    describe 'escapes rule name' do
      let(:rule_name) { '<img src="" />' }

      it 'is shown in reviewer dropdown' do
        find('.js-reviewer-search').click
        wait_for_requests

        page.within '.dropdown-menu-reviewer' do
          expect(page).to have_content(rule_name)
        end
      end
    end
  end

  context 'code owner approval rules', :js do
    let(:code_owner_pattern) { '*' }
    let!(:code_owner_rule) { create(:code_owner_rule, name: code_owner_pattern, merge_request: merge_request, users: [user]) }
    let!(:mr_rule) { create(:approval_merge_request_rule, merge_request: merge_request) }

    it 'displays "Code Owner" text in reviewer dropdown' do
      find('.js-reviewer-search').click
      wait_for_requests

      page.within '.dropdown-menu-reviewer' do
        expect(page).to have_content('Code Owner')
        expect(page).not_to have_content(code_owner_pattern)
      end
    end
  end

  context 'suggested reviewers', :js, :saas do
    let_it_be(:suggested_user) { create(:user) }

    before do
      stub_licensed_features(suggested_reviewers: true)
      stub_feature_flags(suggested_reviewers_control: merge_request.project)

      target_project.project_setting.update!(suggested_reviewers_enabled: true)

      merge_request.project.add_developer(suggested_user)
      merge_request.build_predictions
      merge_request.predictions.update!(suggested_reviewers: { reviewers: [suggested_user.username] })
    end

    it 'displays suggested reviewers in reviewer dropdown', :aggregate_failures do
      find('.js-reviewer-search').click
      wait_for_requests

      help_page_path = help_page_path('user/project/merge_requests/reviews/index', anchor: 'suggested-reviewers')

      page.within '.dropdown-menu-reviewer' do
        expect(page).to have_content('Suggestion(s)')
        expect(page).to have_link(title: 'Learn about suggested reviewers', href: %r{#{help_page_path}})
        expect(page).to have_content(suggested_user.name)
        expect(page).to have_content(suggested_user.username)
        expect(page).to have_css("[data-user-suggested='true']")
      end
    end

    it 'removes headers in reviewer dropdown' do
      find('.js-reviewer-search').click
      wait_for_requests

      page.within '.dropdown-menu-reviewer' do
        click_on suggested_user.name
        expect(page).not_to have_content('Suggestion(s)')
      end
    end
  end
end
