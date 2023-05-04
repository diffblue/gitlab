# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue board filters', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }
  let_it_be(:issue) { create(:issue, project: project, weight: 2, health_status: :on_track, title: "Some title") }
  let_it_be(:issue_2) { create(:issue, project: project, iteration: iteration, weight: 3, title: "Other title") }
  let_it_be(:issue_3) do
    create(:issue, project: project, health_status: :at_risk, title: "Third issue")
  end

  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic, issue: issue, relative_position: 1) }

  before do
    stub_feature_flags(apollo_boards: false)
    stub_licensed_features(epics: true, iterations: true, issuable_health_status: true)

    project.add_maintainer(user)
    sign_in(user)

    visit_project_board
  end

  describe 'filters by epic' do
    it 'lists all epic options' do
      select_tokens('Epic', '=')
      expect_suggestion_count(3)
    end

    it 'loads all the epics when opened and submit one as filter', :aggregate_failures do
      expect_board_list_issue_count(3)

      select_tokens('Epic', '=', epic.title, submit: true)

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue)
    end
  end

  describe 'filters by iteration' do
    it 'list all iteration options' do
      select_tokens('Iteration', '=')

      # None, Any, Current, iteration, Any and Current within cadence
      expect_suggestion_count(6)
    end

    it 'loads all the iterations when opened and submit one as filter', :aggregate_failures do
      expect_board_list_issue_count(3)

      select_tokens('Iteration', '=', iteration.period, submit: true)

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue_2)
    end
  end

  describe 'filters by weight' do
    it 'list all weight options' do
      select_tokens('Weight', '=')

      expect_suggestion_count(23)
    end

    it 'loads all the weights when opened and submit one as filter', :aggregate_failures do
      expect_board_list_issue_count(3)

      select_tokens('Weight', '=', '2', submit: true)

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue)
    end
  end

  describe 'filters by health status' do
    it 'lists all health statuses' do
      select_tokens('Health', '=')
      # 5 items need to be shown: None, Any, On track, Needs attention, At risk
      expect_suggestion_count(5)
    end

    it 'lists all negated health statuses' do
      select_tokens('Health', '!=')
      # 3 items need to be shown:  On track, Needs attention, At risk
      expect_suggestion_count(3)
    end

    it 'loads only on track issues when opened and submit one as filter', :aggregate_failures do
      expect_board_list_issue_count(3)

      select_tokens('Health', '=', 'On track', submit: true)

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue)
      expect_board_list_to_not_contain(issue_2)

      page.refresh

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue)
      expect_board_list_to_not_contain(issue_2)
    end

    it 'loads only issues with a health status that are not on track', :aggregate_failures do
      expect_board_list_issue_count(3)

      select_tokens('Health', '!=', 'On track', 'Health', '=', 'Any', submit: true)

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue_3)
      expect_board_list_to_not_contain(issue)

      page.refresh

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue_3)
      expect_board_list_to_not_contain(issue)
    end

    it 'loads only issues that have no health status', :aggregate_failures do
      expect_board_list_issue_count(3)

      select_tokens('Health', '=', 'None', submit: true)

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue_2)
      expect_board_list_to_not_contain(issue)
      expect_board_list_to_not_contain(issue_3)
    end
  end

  describe 'combined filters' do
    it 'filters on multiple tokens' do
      expect_board_list_issue_count(3)

      select_tokens('Health', '=', 'On track', 'Weight', '=', '2', 'Epic', '=', epic.title)
      send_keys 'Some title', :enter, :enter

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue)

      visit_project_board

      select_tokens('Health', '=', 'None', 'Weight', '!=', '2', 'Epic', '=', 'None', 'Iteration', '=', iteration.period)
      send_keys 'Other title', :enter, :enter

      expect_board_list_issue_count(1)
      expect_board_list_to_contain(issue_2)
    end
  end

  def expect_board_list_issue_count(count)
    expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: count)
  end

  def expect_board_list_to_contain(issue)
    expect(find('.board-card')).to have_content(issue.title)
  end

  def expect_board_list_to_not_contain(issue)
    expect(find('.board-card')).not_to have_content(issue.title)
  end

  def visit_project_board
    visit project_board_path(project, board)
    wait_for_requests
  end
end
