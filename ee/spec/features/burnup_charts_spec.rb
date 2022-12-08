# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Burnup charts', :js, feature_category: :team_planning do
  let_it_be(:burnup_chart_selector) { '.js-burnup-chart' }
  let_it_be(:burndown_chart_selector) { '.js-burndown-chart' }

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:milestone) { create(:milestone, :with_dates, group: group, title: 'January Milestone', description: 'Cut scope from milestone', start_date: '2020-01-30', due_date: '2020-02-10') }
  let_it_be(:other_milestone) { create(:milestone, :with_dates, group: group, title: 'February Milestone', description: 'burnup sample', start_date: '2020-02-11', due_date: '2020-02-28') }

  let_it_be(:issue_1) { create(:issue, created_at: '2020-01-30', project: project, milestone: milestone, weight: 2) }
  let_it_be(:issue_2) { create(:issue, created_at: '2020-01-30', project: project, milestone: milestone, weight: 3) }
  let_it_be(:issue_3) { create(:issue, created_at: '2020-01-30', project: project, milestone: milestone, weight: 2) }

  let_it_be(:event1) { create(:resource_milestone_event, issue: issue_1, milestone: milestone, action: 'add', created_at: '2020-01-30') }
  let_it_be(:event2) { create(:resource_milestone_event, issue: issue_2, milestone: milestone, action: 'add', created_at: '2020-01-30') }
  let_it_be(:event3) { create(:resource_milestone_event, issue: issue_3, milestone: milestone, action: 'add', created_at: '2020-01-30') }

  let_it_be(:event4) { create(:resource_milestone_event, issue: issue_2, milestone: milestone, action: 'remove', created_at: '2020-02-06') }
  let_it_be(:event5) { create(:resource_milestone_event, issue: issue_3, milestone: other_milestone, action: 'add', created_at: '2020-02-06') }

  before do
    group.add_developer(user)
    sign_in(user)
  end

  describe 'licensed feature available' do
    before do
      stub_licensed_features(milestone_charts: true)
    end

    it 'shows burnup chart, with a point per day' do
      visit group_milestone_path(milestone.group, milestone)

      expect(burnup_chart_points.count).to be(12)
    end
  end

  describe 'licensed feature not available' do
    before do
      stub_licensed_features(milestone_charts: false)
    end

    it 'does not show burnup chart' do
      visit group_milestone_path(milestone.group, milestone)

      expect(page).not_to have_selector(burnup_chart_selector)
    end
  end

  def burnup_chart_points
    fill_color = "#617ae2"
    burnup_chart.all("path[fill='#{fill_color}']", count: 12)
  end

  def burnup_chart
    page.find(burnup_chart_selector)
  end
end
