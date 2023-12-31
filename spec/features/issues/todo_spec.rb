# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Manually create a todo item from issue', :js, feature_category: :team_planning do
  let!(:project) { create(:project) }
  let!(:issue)   { create(:issue, project: project) }
  let!(:user)    { create(:user, :no_super_sidebar) }

  before do
    project.add_maintainer(user)
    sign_in(user)
    visit project_issue_path(project, issue)
  end

  it 'creates todo when clicking button' do
    page.within '.issuable-sidebar' do
      click_button 'Add a to do'
      expect(page).to have_content 'Mark as done'
    end

    page.within ".header-content span[aria-label='#{_('Todos count')}']" do
      expect(page).to have_content '1'
    end

    visit project_issue_path(project, issue)

    page.within ".header-content span[aria-label='#{_('Todos count')}']" do
      expect(page).to have_content '1'
    end
  end

  it 'marks a todo as done' do
    page.within '.issuable-sidebar' do
      click_button 'Add a to do'
      click_button 'Mark as done'
    end

    expect(page).to have_selector(".header-content span[aria-label='#{_('Todos count')}']", visible: false)

    visit project_issue_path(project, issue)

    expect(page).to have_selector(".header-content span[aria-label='#{_('Todos count')}']", visible: false)
  end
end
