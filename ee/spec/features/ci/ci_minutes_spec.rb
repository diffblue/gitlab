# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CI minutes', :js, time_travel_to: '2022-06-05' do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, name: 'Project 1', namespace: user.namespace) }

  def create_ci_minutes_usage(minutes, date)
    create(:ci_namespace_monthly_usage, namespace: user.namespace, amount_used: minutes, date: date)
    create(:ci_project_monthly_usage, project: project, amount_used: minutes, date: date)
  end

  before do
    stub_feature_flags(usage_quotas_pipelines_vue: false)
    create_ci_minutes_usage(50, Date.new(Time.zone.now.year, 5, 1))
    create_ci_minutes_usage(60, Date.new(Time.zone.now.year, 6, 1))

    sign_in(user)

    visit profile_usage_quotas_path
  end

  it 'renders two dropdowns of available analytics for project charts' do
    wait_for_requests

    page.find('[data-testid="minutes-usage-project-year-dropdown"]').click

    page.within '[data-testid="minutes-usage-project-year-dropdown"]' do
      expect(page.all('[data-testid="minutes-usage-project-year-dropdown-item"]').size).to eq 1
    end

    page.find('[data-testid="minutes-usage-project-month-dropdown"]').click

    page.within '[data-testid="minutes-usage-project-month-dropdown"]' do
      expect(page.all('[data-testid="minutes-usage-project-month-dropdown-item"]').size).to eq 2
    end
  end
end
