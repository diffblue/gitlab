# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards new issue', :js, feature_category: :team_planning do
  before do
    stub_licensed_features(board_milestone_lists: true)
  end

  let_it_be(:user)            { create(:user) }
  let_it_be(:project)         { create(:project, :public) }
  let_it_be(:milestone)       { create(:milestone, project: project, title: 'Milestone 1') }
  let_it_be(:board)           { create(:board, project: project) }
  let_it_be(:backlog_list)    { create(:backlog_list, board: board) }

  let!(:milestone_list)       { create(:milestone_list, board: board, milestone: milestone, position: 0) }

  context 'authorized user' do
    before do
      stub_feature_flags(apollo_boards: false)

      project.add_maintainer(user)

      sign_in(user)

      visit project_board_path(project, board)
      wait_for_requests

      expect(page).to have_selector('.board', count: 3)
    end

    it 'successfully assigns weight to newly-created issue' do
      create_issue_in_board_list(0)

      page.within(first('[data-testid="issue-boards-sidebar"]')) do
        find('.weight [data-testid="edit-button"]').click
        find('.weight .form-control').set("10\n")
      end

      wait_for_requests

      page.within(first('.board-card')) do
        expect(find('.board-card-weight .board-card-info-text').text).to eq("10")
      end
    end

    describe 'milestone list' do
      it 'successfuly loads milestone to be added to newly created issue' do
        create_issue_in_board_list(1)

        page.within('[data-testid="sidebar-milestones"]') do
          click_button 'Edit'

          wait_for_requests

          expect(page).to have_content 'Milestone 1'
        end
      end
    end
  end

  def create_issue_in_board_list(list_index)
    page.within(all('.board')[list_index]) do
      click_button 'New issue'
    end

    page.within(first('.board-new-issue-form')) do
      find('.form-control').set('new issue')
      click_button 'Create issue'
    end

    wait_for_requests
  end
end
