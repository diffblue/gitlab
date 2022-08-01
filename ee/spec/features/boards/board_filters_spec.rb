# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Issue board filters', :js do
  let_it_be(:group)   { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:board) { create(:board, project: project) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:iteration) { create(:iteration, group: group) }
  let_it_be(:issue) { create(:issue, project: project, weight: 2 ) }
  let_it_be(:issue_2) { create(:issue, project: project, iteration: iteration, weight: 3) }
  let_it_be(:epic_issue1) { create(:epic_issue, epic: epic, issue: issue, relative_position: 1) }

  let(:filtered_search) { find('[data-testid="issue-board-filtered-search"]') }
  let(:filter_input) { find('.gl-filtered-search-term-input') }
  let(:filter_dropdown) { find('.gl-filtered-search-suggestion-list') }
  let(:filter_first_suggestion) { find('.gl-filtered-search-suggestion-list').first('.gl-filtered-search-suggestion') }
  let(:filter_submit) { find('.gl-search-box-by-click-search-button') }

  before do
    stub_licensed_features(epics: true, iterations: true)

    project.add_maintainer(user)
    sign_in(user)

    visit_project_board
  end

  describe 'filters by epic' do
    before do
      set_filter('epic')
    end

    it 'loads all the epics when opened and submit one as filter', :aggregate_failures do
      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 2)

      expect_filtered_search_dropdown_results(filter_dropdown, 3)

      click_on epic.title
      filter_submit.click

      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 1)
      expect(find('.board-card')).to have_content(issue.title)
    end
  end

  describe 'filters by iteration' do
    before do
      set_filter('iteration')
    end

    it 'loads all the iterations when opened and submit one as filter', :aggregate_failures do
      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 2)

      # 6 dropdown items must be shown
      # None, Any, Current, iteration, Any and Current within cadence
      expect_filtered_search_dropdown_results(filter_dropdown, 6)

      click_on iteration.period
      filter_submit.click

      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 1)
      expect(find('.board-card')).to have_content(issue_2.title)
    end
  end

  describe 'filters by weight' do
    before do
      set_filter('weight')
    end

    it 'loads all the weights when opened and submit one as filter', :aggregate_failures do
      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 2)

      expect_filtered_search_dropdown_results(filter_dropdown, 23)

      filter_dropdown.click_on '2'
      filter_submit.click

      expect(find('.board:nth-child(1)')).to have_selector('.board-card', count: 1)
      expect(find('.board-card')).to have_content(issue.title)
    end
  end

  def set_filter(filter)
    filter_input.click
    filter_input.set("#{filter}:")
    filter_first_suggestion.click # Select `=` operator

    wait_for_requests
  end

  def expect_filtered_search_dropdown_results(filter_dropdown, count)
    expect(filter_dropdown).to have_selector('.gl-new-dropdown-item', count: count)
  end

  def visit_project_board
    visit project_board_path(project, board)
    wait_for_requests
  end
end
