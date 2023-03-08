# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'create epic in board', :js, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }

  let_it_be(:epic_board) { create(:epic_board, group: group) }
  let_it_be(:label) { create(:group_label, group: group, name: 'Label1') }
  let_it_be(:label_list) { create(:epic_list, epic_board: epic_board, label: label, position: 0) }
  let_it_be(:backlog_list) { create(:epic_list, epic_board: epic_board, list_type: :backlog) }
  let_it_be(:closed_list) { create(:epic_list, epic_board: epic_board, list_type: :closed) }

  context 'new epics in board list' do
    before do
      stub_feature_flags(apollo_boards: false)
      stub_licensed_features(epics: true)
      group.add_maintainer(user)
      sign_in(user)
      visit_epic_boards_page
    end

    it 'creates new epic and opens sidebar', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/394693' do
      page.within(first('.board')) do
        dropdown = first("[data-testid='header-list-actions']")
        dropdown.click
        click_button 'Create new epic'
      end

      page.within(first('.board-new-issue-form')) do
        find('.form-control').set('epic bug')
        click_button 'Create epic'
      end

      wait_for_requests

      page.within(first('.board [data-testid="issue-count-badge"]')) do
        expect(page).to have_content('1')
      end

      page.within(first('.board-card')) do
        epic = group.epics.find_by_title('epic bug')

        expect(page).to have_content(epic.to_reference)
        expect(page).to have_link(epic.title, href: /#{epic_path(epic)}/)
      end

      expect(page).to have_selector('[data-testid="epic-boards-sidebar"]')
    end

    def visit_epic_boards_page
      visit group_epic_boards_path(group)
      wait_for_requests
    end
  end
end
