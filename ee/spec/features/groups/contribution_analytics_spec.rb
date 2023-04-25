# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Groups > Contribution Analytics', :js, feature_category: :value_stream_management do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:empty_project) { create(:project, namespace: group) }

  def visit_contribution_analytics
    visit group_path(group)

    within('.nav-sidebar') do
      find('a', text: 'Analytics').click

      within('.sidebar-sub-level-items') do
        find('a', text: 'Contribution').click
      end
    end
  end

  before do
    group.add_owner(user)
    sign_in(user)
  end

  describe 'visit Contribution Analytics page for group' do
    before do
      visit_contribution_analytics
    end

    it 'displays Contribution Analytics' do
      expect(page).to have_content "Contribution analytics for issues, merge requests and push"
    end

    it 'displays text indicating no pushes, merge requests and issues' do
      expect(page).to have_content "No pushes for the selected time period."
      expect(page).to have_content "No merge requests for the selected time period."
      expect(page).to have_content "No issues for the selected time period."
    end
  end

  describe 'Contribution Analytics Tabs' do
    before do
      visit group_contribution_analytics_path(group)
    end

    it 'displays the Date Range GlTabs' do
      page.within '[data-testid="contribution-analytics-date-nav"]' do
        expect(page).to have_link 'Last week',
          href: group_contribution_analytics_path(group, start_date: 1.week.ago.to_date)
        expect(page).to have_link 'Last month',
          href: group_contribution_analytics_path(group, start_date: 1.month.ago.to_date)
        expect(page).to have_link 'Last 3 months',
          href: group_contribution_analytics_path(group, start_date: 3.months.ago.to_date)
      end
    end

    it 'defaults active to Last Week' do
      page.within '[data-testid="contribution-analytics-date-nav"]' do
        expect(page.find('.active')).to have_text('Last week')
      end
    end

    it 'clicking a different option updates correctly' do
      page.within '[data-testid="contribution-analytics-date-nav"]' do
        page.find_link('Last 3 months').click
      end

      wait_for_requests

      page.within '[data-testid="contribution-analytics-date-nav"]' do
        expect(page.find('.active')).to have_text('Last 3 months')
      end
    end
  end
end
