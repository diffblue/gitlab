# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'GFM autocomplete EE', :js, feature_category: :team_planning do
  let_it_be(:user) { create(:user, name: '💃speciąl someone💃', username: 'someone.special') }
  let_it_be(:another_user) { create(:user, name: 'another user', username: 'another.user') }
  let_it_be(:project) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project, assignees: [user]) }

  before do
    project.add_maintainer(user)
  end

  context 'assignees' do
    before do
      sign_in(user)

      visit project_issue_path(project, issue)
    end

    it 'only lists users who are currently assigned to the issue when using /unassign' do
      fill_in 'Comment', with: '/una'

      find_highlighted_autocomplete_item.click

      wait_for_requests

      expect(find_autocomplete_menu).to have_text(user.username)
      expect(find_autocomplete_menu).not_to have_text(another_user.username)
    end
  end

  private

  def find_autocomplete_menu
    find('.atwho-view ul', visible: true)
  end

  def find_highlighted_autocomplete_item
    find('.atwho-view li.cur', visible: true)
  end
end
