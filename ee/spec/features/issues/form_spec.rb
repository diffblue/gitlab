# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'New/edit issue', :js, feature_category: :team_planning do
  include GitlabRoutingHelper
  include ActionView::Helpers::JavaScriptHelper
  include FormHelper
  include ContentEditorHelpers

  let!(:project)   { create(:project) }
  let!(:user)      { create(:user) }
  let!(:user2)     { create(:user) }
  let!(:milestone) { create(:milestone, project: project) }
  let!(:label)     { create(:label, project: project) }
  let!(:label2)    { create(:label, project: project) }
  let!(:issue)     { create(:issue, project: project, assignees: [user], milestone: milestone) }

  before do
    project.add_maintainer(user)
    project.add_maintainer(user2)

    allow_any_instance_of(ApplicationHelper).to receive(:collapsed_sidebar?).and_return(true)

    stub_licensed_features(multiple_issue_assignees: true)
    gitlab_sign_in(user)
  end

  context 'new issue' do
    before do
      visit new_project_issue_path(project)
      close_rich_text_promo_popover_if_present
    end

    describe 'shorten users API pagination limit' do
      before do
        # Using `allow_any_instance_of`/`and_wrap_original`, `original` would
        # somehow refer to the very block we defined to _wrap_ that method, instead of
        # the original method, resulting in infinite recursion when called.
        # This is likely a bug with helper modules included into dynamically generated view classes.
        # To work around this, we have to hold on to and call to the original implementation manually.
        original_issue_dropdown_options = FormHelper.instance_method(:assignees_dropdown_options)
        allow_any_instance_of(FormHelper).to receive(:assignees_dropdown_options).and_wrap_original do |original, *args|
          options = original_issue_dropdown_options.bind_call(original.receiver, *args)
          options[:data][:per_page] = 2

          options
        end

        visit new_project_issue_path(project)

        click_button 'Unassigned'
      end

      it 'displays selected users even if they are not part of the original API call' do
        fill_in 'Search users', with: user2.name
        click_link user2.name
        find('.js-dropdown-input-clear').click

        page.within '.dropdown-menu-user' do
          expect(page).to have_content user.name
          expect(find('.dropdown-menu-user a.is-active').first(:xpath, '..')['data-user-id']).to eq(user2.id.to_s)
        end
      end
    end

    describe 'multiple assignees' do
      before do
        click_button 'Unassigned'
      end

      it 'unselects other assignees when unassigned is selected' do
        click_link user2.name
        click_link 'Unassigned'

        expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match('0')
      end

      it 'toggles assign to me when current user is selected and unselected' do
        click_link user.name

        expect(page).not_to have_link 'Assign to me'

        click_link user.name

        expect(page).to have_link 'Assign to me'
      end
    end

    it 'allows user to create new issue' do
      fill_in 'Title (required)', with: 'title'
      fill_in 'Description', with: 'title'

      expect(page).to have_link 'Assign to me'

      click_button 'Unassigned'
      click_link user2.name

      expect(find('input[name="issue[assignee_ids][]"]', visible: false).value).to match(user2.id.to_s)
      expect(page).to have_button user2.name

      click_button 'Close'
      click_link 'Assign to me'

      assignee_ids = page.all('input[name="issue[assignee_ids][]"]', visible: false)
      expect(assignee_ids[0].value).to match(user2.id.to_s)
      expect(assignee_ids[1].value).to match(user.id.to_s)

      expect(page).to have_button "#{user2.name} + 1 more"
      expect(page).not_to have_link 'Assign to me'

      click_button 'Select milestone'
      click_button milestone.title

      expect(find('input[name="issue[milestone_id]"]', visible: false).value).to match(milestone.id.to_s)
      expect(page).to have_button milestone.title

      click_button _('Select label')
      wait_for_all_requests
      within_testid('sidebar-labels') do
        click_button label.title
        click_button label2.title
        click_button _('Close')
        wait_for_requests
      end

      expect(page).to have_button label.title
      within_testid('embedded-labels-list') do
        expect(page).to have_content(label.title)
        expect(page).to have_content(label2.title)
      end

      fill_in 'issue_weight', with: '1'
      click_button 'Create issue'

      page.within '.issuable-sidebar' do
        page.within '.assignee' do
          expect(page).to have_text "2 Assignees"
        end

        page.within '.milestone' do
          expect(page).to have_text milestone.title
        end

        page.within '.labels' do
          expect(page).to have_text label.title
          expect(page).to have_text label2.title
        end

        page.within '.weight' do
          expect(page).to have_text '1'
        end
      end

      page.within '.breadcrumbs' do
        issue = Issue.find_by(title: 'title')

        expect(page).to have_text("Issues #{issue.to_reference}")
      end
    end

    it 'correctly updates the selected user when changing assignee' do
      click_button 'Unassigned'
      click_link user.name

      expect(page).to have_button(user.name)

      click_link user2.name

      expect(page.all('input[name="issue[assignee_ids][]"]', visible: false)[0].value).to match(user.id.to_s)
      expect(page.all('input[name="issue[assignee_ids][]"]', visible: false)[1].value).to match(user2.id.to_s)
      expect(page.all('.dropdown-menu-user a.is-active').length).to eq(2)
      expect(page.all('.dropdown-menu-user a.is-active')[0].first(:xpath, '..')['data-user-id']).to eq(user.id.to_s)
      expect(page.all('.dropdown-menu-user a.is-active')[1].first(:xpath, '..')['data-user-id']).to eq(user2.id.to_s)
    end
  end

  def before_for_selector(selector)
    js = <<-JS.strip_heredoc
      (function(selector) {
        var el = document.querySelector(selector);
        return window.getComputedStyle(el, '::before').getPropertyValue('content');
      })("#{escape_javascript(selector)}")
    JS
    page.evaluate_script(js)
  end
end
