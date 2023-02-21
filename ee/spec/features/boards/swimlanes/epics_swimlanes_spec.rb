# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'epics swimlanes', :js, feature_category: :team_planning do
  include BoardHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, :public, group: group) }

  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:label) { create(:label, project: project, name: 'Label1') }
  let_it_be(:list) { create(:list, board: board, label: label, position: 0) }
  let_it_be(:backlog_list) { create(:backlog_list, board: board) }

  let_it_be(:issue1) { create(:issue, project: project, labels: [label]) }
  let_it_be(:issue2) { create(:issue, project: project) }
  let_it_be(:issue3) { create(:issue, project: project) }

  let_it_be(:epic1) { create(:epic, group: group) }
  let_it_be(:epic2) { create(:epic, group: group) }

  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic1, issue: issue1) }
  let_it_be(:epic_issue2) { create(:epic_issue, epic: epic2, issue: issue2) }

  context 'link to swimlanes view' do
    before do
      stub_licensed_features(epics: true, swimlanes: true)
      stub_feature_flags(apollo_boards: false)
      sign_in(user)
      visit_epics_swimlanes_page
    end

    it 'displays epics swimlanes when link to boards with group_by epic in URL' do
      expect(page).to have_selector('[data-testid="board-swimlanes"]')

      wait_for_all_requests

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(2)
    end

    it 'displays issue not assigned to epic title and unassigned issues lane only on expand' do
      expect(page).not_to have_selector('[data-testid="board-lane-unassigned-issues"]')

      load_unassigned_issues

      expect(page).to have_selector('[data-testid="board-lane-unassigned-issues"]')
    end

    it 'displays default lists and a label list' do
      lists = %w[Open Label1 Closed]

      wait_for_requests

      expect(page).to have_selector('.board-header', count: 3)

      page.all('.board-header').each_with_index do |list, i|
        expect(list.find('.board-title')).to have_content(lists[i])
      end
    end
  end

  before do
    stub_licensed_features(epics: true, swimlanes: true)
    stub_feature_flags(apollo_boards: false)
    sign_in(user)
    visit_board_page
    load_epic_swimlanes
  end

  context 'switch to swimlanes view' do
    it 'displays epics swimlanes when selecting Epic in Group by dropdown' do
      expect(page).to have_selector('[data-testid="board-swimlanes"]')

      epic_lanes = page.all(:css, '.board-epic-lane')
      expect(epic_lanes.length).to eq(2)
    end

    it 'displays issue not assigned to epic title and unassigned issues lane only on expand' do
      expect(page).not_to have_selector('[data-testid="board-lane-unassigned-issues"]')

      load_unassigned_issues

      expect(page).to have_selector('[data-testid="board-lane-unassigned-issues"]')
    end
  end

  context 'issue cards' do
    let(:issue_card) { first("[data-testid='board-epic-lane-issues'] [data-testid='board_card']") }

    before do
      wait_for_all_requests

      issue_card.click
    end

    it 'highlights an issue card on click' do
      expect(issue_card[:class]).to include('is-active')
      expect(issue_card[:class]).not_to include('multi-select')
    end

    it 'unhighlights a selected issue card on click' do
      issue_card.click

      expect(issue_card[:class]).not_to include('is-active')
      expect(issue_card[:class]).not_to include('multi-select')
    end
  end

  context 'add issue to swimlanes list' do
    let(:dropdown) { first("[data-testid='header-list-actions']") }

    before do
      wait_for_all_requests

      load_unassigned_issues
      dropdown.click
    end

    it 'displays new issue button' do
      expect(first('.board')).to have_button('Create new issue', count: 1)
    end

    it 'shows form in unassigned issues lane when clicking button' do
      page.within(first('.board')) do
        click_button 'Create new issue'
      end

      page.within("[data-testid='board-lane-unassigned-issues']") do
        expect(page).to have_selector('.board-new-issue-form')
      end
    end

    it 'hides form when clicking cancel' do
      page.within(first('.board')) do
        click_button 'Create new issue'
      end

      page.within("[data-testid='board-lane-unassigned-issues']") do
        expect(page).to have_selector('.board-new-issue-form')

        click_button 'Cancel'

        expect(page).not_to have_selector('.board-new-issue-form')
      end
    end

    it 'creates new issue in unassigned issues lane' do
      page.within(first('.board')) do
        click_button 'Create new issue'
      end

      wait_for_all_requests

      page.within(first('.board-new-issue-form')) do
        find('.form-control').set('bug')
        click_button 'Create issue'
      end

      wait_for_all_requests

      page.within(first('.board [data-testid="issue-count-badge"]')) do
        expect(page).to have_content('3')
      end

      wait_for_all_requests

      page.within("[data-testid='board-lane-unassigned-issues']") do
        page.within(first('.board-card')) do
          issue = project.issues.find_by!(title: 'bug')

          expect(page).to have_content(issue.to_reference)
        end
      end
    end
  end

  def visit_board_page
    visit project_boards_path(project)
    wait_for_requests
  end

  def visit_epics_swimlanes_page
    visit "#{project_boards_path(project)}?group_by=epic"
    wait_for_requests
  end
end
