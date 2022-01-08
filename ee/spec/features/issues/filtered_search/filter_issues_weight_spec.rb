# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter issues weight', :js do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:label) { create(:label, project: project, title: 'urgent') }
  let_it_be(:milestone) { create(:milestone, title: 'version1', project: project) }
  let_it_be(:issue1) { create(:issue, project: project, weight: 1) }
  let_it_be(:issue2) { create(:issue, project: project, weight: 2, title: 'Bug report 1', milestone: milestone, author: user, assignees: [user], labels: [label]) }

  let(:filter_dropdown) { find("#js-dropdown-weight .filter-dropdown") }

  def expect_issues_list_count(open_count, closed_count = 0)
    all_count = open_count + closed_count

    expect(page).to have_issuable_counts(open: open_count, closed: closed_count, all: all_count)
    page.within '.issues-list' do
      expect(page).to have_selector('.issue', count: open_count)
    end
  end

  before do
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the weights when opened' do
      input_filtered_search('weight:=', submit: false, extra_space: false)

      expect_filtered_search_dropdown_results(filter_dropdown, 21)
    end
  end

  describe 'only weight' do
    it 'filter issues by searched weight' do
      input_filtered_search('weight:=1')

      expect_issues_list_count(1)
    end
  end

  describe 'negated weight only' do
    let(:search) { 'weight:!=2' }

    it 'excludes issues with specified weight' do
      input_filtered_search(search)

      expect_issues_list_count(1)
    end
  end

  describe 'weight with other filters' do
    it 'filters issues by searched weight and text' do
      search = "weight:=2 bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, author and text' do
      search = "weight:=2 author:=@root bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, author, assignee and text' do
      search = "weight:=2 author:=@root assignee:=@root bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, author, assignee, label and text' do
      search = "weight:=2 author:=@root assignee:=@root label:=~urgent bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end

    it 'filters issues by searched weight, milestone and text' do
      search = "weight:=2 milestone:=%version1 bug"
      input_filtered_search(search)

      expect_issues_list_count(1)
      expect_filtered_search_input('bug')
    end
  end
end
