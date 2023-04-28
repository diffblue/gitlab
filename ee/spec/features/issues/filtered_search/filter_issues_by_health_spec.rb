# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Filter issues health status', :js, feature_category: :team_planning do
  include FilteredSearchHelpers

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, name: 'administrator', username: 'root') }
  let_it_be(:label) { create(:label, project: project, title: 'urgent') }
  let_it_be(:milestone) { create(:milestone, title: 'version1', project: project) }
  let_it_be(:issue1) { create(:issue, project: project, health_status: :on_track) }
  let_it_be(:issue2) do
    create(:issue,
      project: project,
      health_status: :at_risk,
      title: 'Bug report 1',
      milestone: milestone,
      author: user,
      assignees: [user],
      labels: [label]
    )
  end

  let_it_be(:issue3) { create(:issue, project: project) }

  def expect_issues_list_count(open_count, closed_count = 0)
    all_count = open_count + closed_count

    expect(page).to have_issuable_counts(open: open_count, closed: closed_count, all: all_count)
    page.within '.issues-list' do
      expect(page).to have_selector('.issue', count: open_count)
      expect(page).to have_selector('.issue', count: all_count)
    end
  end

  def expect_issues_list_to_contain(issues)
    page.within '.issues-list' do
      issues.each do |issue|
        expect(page).to have_text(issue.title)
      end
    end
  end

  def expect_issues_list_to_not_contain(issues)
    page.within '.issues-list' do
      issues.each do |issue|
        expect(page).not_to have_text(issue.title)
      end
    end
  end

  before do
    stub_feature_flags(or_issuable_queries: false)
    stub_licensed_features(issuable_health_status: true)
    project.add_maintainer(user)
    sign_in(user)

    visit project_issues_path(project)
  end

  describe 'behavior' do
    it 'loads all the health statuses when opened for =' do
      select_tokens 'Health', '='

      # Expect Any, None, On track, Needs attention and At risk
      expect_suggestion_count 5
    end

    it 'loads all the health statuses when opened for !=' do
      select_tokens 'Health', '!='

      # Expect On track, Needs attention and At risk
      expect_suggestion_count 3
    end
  end

  describe 'only health' do
    it 'filter issues by searched health status' do
      select_tokens 'Health', '=', 'On track', submit: true

      expect_issues_list_count(1)
      expect_issues_list_to_contain([issue1])
      expect_issues_list_to_not_contain([issue2])
    end

    it 'filter issues by Any health status' do
      select_tokens 'Health', '=', 'Any', submit: true

      expect_issues_list_count(2)
      expect_issues_list_to_contain([issue1, issue2])
      expect_issues_list_to_not_contain([issue3])
    end

    it 'filter issues by None health status' do
      select_tokens 'Health', '=', 'None', submit: true

      expect_issues_list_count(1)
      expect_issues_list_to_contain([issue3])
      expect_issues_list_to_not_contain([issue1, issue2])
    end

    it 'filter issues by not on track health status' do
      select_tokens 'Health', '!=', 'On track', submit: true

      expect_issues_list_count(2)
      expect_issues_list_to_contain([issue2, issue3])
      expect_issues_list_to_not_contain([issue1])
    end

    it 'filter issues by any health status but not on track' do
      select_tokens 'Health', '!=', 'On track', 'Health', '=', 'Any', submit: true

      expect_issues_list_count(1)
      expect_issues_list_to_contain([issue2])
      expect_issues_list_to_not_contain([issue1, issue3])
    end
  end

  describe 'health with other filters' do
    it 'filters issues by searched health and text' do
      select_tokens 'Health', '=', 'At risk'
      send_keys 'bug', :enter, :enter

      expect_issues_list_count 1
      expect_issues_list_to_contain([issue2])
      expect_issues_list_to_not_contain([issue1])
      expect_search_term 'bug'
    end

    it 'filters issues by searched health, author and text' do
      select_tokens 'Health', '=', 'At risk', 'Author', '=', user.username
      send_keys 'bug', :enter, :enter

      expect_issues_list_count 1
      expect_issues_list_to_contain([issue2])
      expect_issues_list_to_not_contain([issue1])
      expect_search_term 'bug'
    end

    it 'filters issues by searched health, author, assignee and text' do
      select_tokens 'Health', '=', 'At risk', 'Author', '=', user.username, 'Assignee', '=', user.username
      send_keys 'bug', :enter, :enter

      expect_issues_list_count 1
      expect_issues_list_to_contain([issue2])
      expect_issues_list_to_not_contain([issue1])
      expect_search_term 'bug'
    end

    it 'filters issues by searched health, author, assignee, label and text' do
      select_tokens 'Health', '=', 'At risk', 'Author', '=', user.username
      select_tokens 'Assignee', '=', user.username, 'Label', '=', label.title
      send_keys 'bug', :enter, :enter

      expect_issues_list_count 1
      expect_issues_list_to_contain([issue2])
      expect_issues_list_to_not_contain([issue1])
      expect_search_term 'bug'
    end

    it 'filters issues by searched health, milestone and text' do
      select_tokens 'Health', '=', 'At risk', 'Milestone', '=', milestone.title
      send_keys 'bug', :enter, :enter

      expect_issues_list_count 1
      expect_issues_list_to_contain([issue2])
      expect_issues_list_to_not_contain([issue1])
      expect_search_term 'bug'
    end

    it 'filters issues by not on track, milestone and text' do
      select_tokens 'Health', '!=', 'On track', 'Milestone', '=', milestone.title
      send_keys 'bug', :enter, :enter

      expect_issues_list_count 1
      expect_issues_list_to_contain([issue2])
      expect_issues_list_to_not_contain([issue1, issue3])
    end
  end
end
