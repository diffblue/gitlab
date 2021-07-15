# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards new issue', :js do
  let_it_be(:user)         { create(:user) }
  let_it_be(:project)      { create(:project, :public) }
  let_it_be(:board)        { create(:board, project: project) }
  let_it_be(:backlog_list) { create(:backlog_list, board: board) }

  context 'authorized user' do
    before do
      project.add_maintainer(user)

      sign_in(user)

      visit project_board_path(project, board)
      wait_for_requests

      expect(page).to have_selector('.board', count: 2)
    end

    it 'successfully assigns weight to newly-created issue' do
      page.within(first('.board')) do
        find('.issue-count-badge-add-button').click
      end

      page.within(first('.board-new-issue-form')) do
        fill_in 'issue_title', with: 'new issue'

        click_button 'Create issue'
      end

      wait_for_requests

      page.within(first('.board')) do
        find('.board-card').click
      end

      page.within(first('[data-testid="issue-boards-sidebar"]')) do
        find('.weight [data-testid="edit-button"]').click
        find('.weight .form-control').set("10\n")
      end

      wait_for_requests

      page.within(first('.board-card')) do
        expect(find('.board-card-weight .board-card-info-text').text).to eq("10")
      end
    end
  end
end
