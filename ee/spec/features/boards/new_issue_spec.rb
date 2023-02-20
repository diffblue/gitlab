# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue Boards new issue', :js, feature_category: :team_planning do
  before do
    stub_licensed_features(board_milestone_lists: true)
  end

  let_it_be(:user)            { create(:user) }
  let_it_be(:group)           { create(:group, :public) }
  let_it_be(:project)         { create(:project, :public, group: group) }
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

    describe 'board scoped to current iteration' do
      let!(:iteration) do
        create(:current_iteration, iterations_cadence: create(:iterations_cadence, group: group),
          start_date: 3.days.ago, due_date: 3.days.from_now)
      end

      it 'adds a new issue' do
        scope_board_to_current_iteration

        expect { create_issue_in_board_list(0) }.to change { Issue.count }.by(1)

        page.within('[data-testid="iteration-edit"]') do
          expect(page).to have_content iteration.title
        end

        page.within('.board-card') do
          expect(page).to have_content 'new issue'
        end
      end
    end
  end

  def create_issue_in_board_list(list_index)
    page.within(all('.board')[list_index]) do
      dropdown = first("[data-testid='header-list-actions']")
      dropdown.click
      click_button 'Create new issue'
    end

    page.within(first('.board-new-issue-form')) do
      find('.form-control').set('new issue')
      click_button 'Create issue'
    end

    wait_for_requests
  end

  def click_on_board_modal
    find('.board-config-modal .modal-content').click
  end

  def scope_board_to_current_iteration
    find('.btn', text: 'Edit board').click

    page.within(".iteration") do
      click_button 'Edit'

      page.within(".dropdown-menu") do
        click_button "Current"
      end
    end

    click_on_board_modal

    click_button 'Save changes'

    wait_for_requests
  end
end
