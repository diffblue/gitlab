# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Group CI/CD Analytics', :js, feature_category: :value_stream_management do
  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }
  let_it_be(:project_1) { create(:project, group: group) }
  let_it_be(:project_2) { create(:project, group: group) }
  let_it_be(:project_3) { create(:project, group: subgroup) }
  let_it_be(:unrelated_project) { create(:project) }
  let_it_be(:releases) { create_list(:release, 10, project: project_1) }
  let_it_be(:releases) { create_list(:release, 5, project: project_3) }
  let_it_be(:unrelated_release) { create(:release, project: unrelated_project) }

  forecast_toggle_selector = '[data-testid="data-forecast-toggle"] button'
  chart_series_legend_selector = '[data-testid="deployment-frequency-charts"] .gl-legend-inline'

  before do
    stub_licensed_features(group_ci_cd_analytics: true, dora4_analytics: true)
    group.add_reporter(user)
    sign_in(user)
    visit group_analytics_ci_cd_analytics_path(group)
    wait_for_requests
  end

  it 'renders statistics about release within the group', :aggregate_failures do
    within '[data-testid="release-stats-card"]' do
      expect(page).to have_content 'Releases All time'

      expect(page).to have_content '15 Releases 67% Projects with releases'
    end
  end

  shared_examples 'a DORA chart' do |selector, title|
    it "render the #{title} charts", :aggregate_failures do
      click_link(title)

      within selector do
        expect(page).to have_content title

        expect(page).to have_content 'Last week Last month Last 90 days'

        expect(page).to have_content 'Date range:'
      end
    end
  end

  describe 'DORA charts' do
    it_behaves_like 'a DORA chart', '[data-testid="deployment-frequency-charts"]', 'Deployment frequency'

    it_behaves_like 'a DORA chart', '[data-testid="lead-time-charts"]', 'Lead time'

    it_behaves_like 'a DORA chart', '[data-testid="time-to-restore-service-charts"]', 'Time to restore service'

    it_behaves_like 'a DORA chart', '[data-testid="change-failure-rate-charts"]', 'Change failure rate'
  end

  describe 'Deployment frequency' do
    let(:toggle) { page.find(forecast_toggle_selector) }

    before do
      click_link('Deployment frequency')
    end

    it 'can toggle data forecasting', quarantine: 'https://gitlab.com/gitlab-org/gitlab/-/issues/410102' do
      expect(page).to have_css(forecast_toggle_selector)
      expect(toggle[:class].include?('is-checked')).to be(false)

      within chart_series_legend_selector do
        expect(page).not_to have_content "Forecast"
      end

      find(forecast_toggle_selector).click
      expect(page).to have_text("Accept testing terms of use?")

      click_button('Accept testing terms')
      wait_for_requests
      expect(toggle[:class].include?('is-checked')).to be(true)

      within chart_series_legend_selector do
        expect(page).to have_content "Forecast"
      end

      find(forecast_toggle_selector).click
      expect(toggle[:class].include?('is-checked')).to be(false)
    end
  end

  describe 'when dora_charts_forecast is disabled' do
    before do
      stub_licensed_features(group_ci_cd_analytics: true, dora4_analytics: true)
      stub_feature_flags(dora_charts_forecast: false)
      group.add_reporter(user)
      sign_in(user)
      visit group_analytics_ci_cd_analytics_path(group)
      wait_for_requests
    end

    it 'can not toggle data forecasting' do
      click_link('Deployment frequency')

      expect(page).not_to have_css(forecast_toggle_selector)
    end
  end
end
