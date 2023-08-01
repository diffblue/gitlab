# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project > Settings > Analytics -> Data sources -> Product analytics instance settings', :js, feature_category: :product_analytics_visualization do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group).tap { |g| g.add_owner(user) } }
  let_it_be(:project) { create(:project, namespace: group) }

  before do
    sign_in(user)
  end

  context 'without correct license' do
    before do
      stub_licensed_features(product_analytics: false)
      stub_feature_flags(product_analytics_admin_settings: true, product_analytics_dashboards: true)

      visit project_settings_analytics_path(project)
    end

    it 'does not show product analytics configuration options' do
      expect(page).not_to have_content s_('Product analytics')
    end
  end

  context 'without correct feature flags enabled' do
    where(:product_analytics_admin_settings, :product_analytics_dashboards) do
      true | false
      false | true
      false | false
    end

    with_them do
      before do
        stub_licensed_features(product_analytics: true)
        stub_feature_flags(product_analytics_admin_settings: product_analytics_admin_settings,
          product_analytics_dashboards: product_analytics_dashboards)

        visit project_settings_analytics_path(project)
      end

      it 'does not show product analytics configuration options' do
        expect(page).not_to have_content s_('Product analytics')
      end
    end
  end

  context 'with valid license and feature flags' do
    before do
      stub_licensed_features(product_analytics: true)
      stub_feature_flags(product_analytics_admin_settings: true, product_analytics_dashboards: true)
      visit project_settings_analytics_path(project)
    end

    it 'shows product analytics options' do
      expect(page).to have_content s_('Product analytics')
    end

    it 'saves configuration options' do
      configurator_connection_string = 'https://configurator.example.com'
      collector_host = 'https://collector.example.com'
      clickhouse_connection_string = 'https://clickhouse.example.com'
      cube_api_base_url = 'https://cube.example.com'
      cube_api_key = '123-cubejs-4-me'

      fill_in('Product analytics configurator connection string', with: configurator_connection_string)
      fill_in('Collector host', with: collector_host)
      fill_in('Clickhouse URL', with: clickhouse_connection_string)
      fill_in('Cube API URL', with: cube_api_base_url)
      fill_in('Cube API key', with: cube_api_key)

      click_button 'Save changes'
      wait_for_requests

      expect(page).to have_field('Product analytics configurator connection string',
        with: configurator_connection_string)
      expect(page).to have_field('Collector host', with: collector_host)
      expect(page).to have_field('Clickhouse URL', with: clickhouse_connection_string)
      expect(page).to have_field('Cube API URL', with: cube_api_base_url)
      expect(page).to have_field('Cube API key', with: cube_api_key)
    end
  end
end
