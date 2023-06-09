# frozen_string_literal: true

require 'spec_helper'
require_relative '../product_analytics/dashboards_shared_examples'

RSpec.describe 'Analytics Dashboard', :js, feature_category: :product_analytics do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project, :repository) }

  before do
    sign_in(user)
    project.reload
  end

  subject(:visit_page) { visit project_analytics_dashboards_path(project) }

  shared_examples 'renders not found' do
    before do
      visit_page
    end

    it do
      expect(page).to have_content(s_('404|Page Not Found'))
    end
  end

  context 'with the combined dashboards feature flag disabled' do
    before do
      stub_feature_flags(combined_analytics_dashboards: false, product_analytics_snowplow_support: false)
    end

    it_behaves_like 'renders not found'
  end

  context 'with the combined dashboards feature flag enabled' do
    before do
      stub_feature_flags(combined_analytics_dashboards: true, product_analytics_snowplow_support: false)
    end

    context 'with the licensed feature disabled' do
      before do
        stub_licensed_features(combined_project_analytics_dashboards: false)
      end

      it_behaves_like 'renders not found'
    end

    context 'with the licensed feature enabled' do
      before do
        stub_licensed_features(combined_project_analytics_dashboards: true)
      end

      context 'without access to the project' do
        it_behaves_like 'renders not found'
      end

      context 'with access to the project' do
        before do
          project.add_guest(user)
        end

        context 'when loading the default page' do
          before do
            visit_page
          end

          it 'renders the dashboards list' do
            expect(page).to have_content('Analytics dashboards')
          end
        end

        it_behaves_like 'product analytics dashboards' do
          let(:project_settings) { { jitsu_key: 123 } }
          let(:application_settings) do
            {
              jitsu_host: 'https://jitsu.example.com',
              jitsu_project_xid: '123',
              jitsu_administrator_email: 'test@example.com',
              jitsu_administrator_password: 'password',
              product_analytics_data_collector_host: 'https://collector.example.com',
              product_analytics_clickhouse_connection_string: 'clickhouse://localhost:9000',
              cube_api_base_url: 'https://cube.example.com',
              cube_api_key: '123'
            }
          end
        end

        context 'with snowplow enabled' do
          before do
            stub_feature_flags(combined_analytics_dashboards: true, product_analytics_snowplow_support: true)
          end

          context 'when loading the default page' do
            before do
              visit_page
            end

            it 'renders the dashboards list' do
              expect(page).to have_content('Analytics dashboards')
            end
          end

          it_behaves_like 'product analytics dashboards' do
            let(:project_settings) { { product_analytics_instrumentation_key: 456 } }
            let(:application_settings) do
              {
                product_analytics_configurator_connection_string: 'https://configurator.example.com',
                product_analytics_data_collector_host: 'https://collector.example.com',
                cube_api_base_url: 'https://cube.example.com',
                cube_api_key: '123'
              }
            end
          end
        end
      end
    end
  end
end
