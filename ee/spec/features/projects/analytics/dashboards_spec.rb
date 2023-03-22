# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Analytics Dashboard', :js, feature_category: :product_analytics do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:query_response_with_unknown_error) { fixture_file('cube_js/query_with_error.json', dir: 'ee') }
  let_it_be(:query_response_with_no_db_error) { fixture_file('cube_js/query_with_no_db_error.json', dir: 'ee') }
  let_it_be(:query_response_with_data) { fixture_file('cube_js/query_with_data.json', dir: 'ee') }

  let(:cube_api_url) { "https://cube.example.com/cubejs-api/v1/load" }

  before do
    sign_in(user)
    project.project_setting.update!(jitsu_key: '123')
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

  shared_examples 'renders the product analytics dashboards' do
    before do
      visit_page
    end

    it do
      expect(page).to have_content('Understand your audience')
    end
  end

  shared_examples 'does not render the product analytics dashboards' do
    before do
      visit_page
    end

    it do
      expect(page).not_to have_content('Understand your audience')
    end
  end

  context 'with the combined dashboards feature flag disabled' do
    before do
      stub_feature_flags(combined_analytics_dashboards: false)
    end

    it_behaves_like 'renders not found'
  end

  context 'with the combined dashboards feature flag enabled' do
    before do
      stub_feature_flags(combined_analytics_dashboards: true)
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

          it_behaves_like 'does not render the product analytics dashboards'
        end

        context 'for product analytics' do
          context 'with the required application settings' do
            before do
              stub_application_setting(product_analytics_enabled?: true)
              stub_application_setting(jitsu_host: 'https://jitsu.example.com')
              stub_application_setting(jitsu_project_xid: '123')
              stub_application_setting(jitsu_administrator_email: 'test@example.com')
              stub_application_setting(jitsu_administrator_password: 'password')
              stub_application_setting(product_analytics_data_collector_host: 'https://collector.example.com')
              stub_application_setting(product_analytics_clickhouse_connection_string: 'clickhouse://localhost:9000')
              stub_application_setting(cube_api_base_url: 'https://cube.example.com')
              stub_application_setting(cube_api_key: '123')
            end

            context 'with the feature flag disabled' do
              before do
                stub_feature_flags(product_analytics_dashboards: false)
              end

              it_behaves_like 'does not render the product analytics dashboards'
            end

            context 'with the feature flag enabled' do
              before do
                stub_feature_flags(product_analytics_dashboards: true)
              end

              context 'with the licensed feature disabled' do
                before do
                  stub_licensed_features(combined_project_analytics_dashboards: true, product_analytics: false)
                end

                it_behaves_like 'does not render the product analytics dashboards'
              end

              context 'with the licensed feature enabled' do
                before do
                  stub_licensed_features(combined_project_analytics_dashboards: true, product_analytics: true)
                end

                context 'without the correct user permissions' do
                  it_behaves_like 'does not render the product analytics dashboards'
                end

                context 'with the correct user permissions' do
                  before do
                    project.add_developer(user)
                  end

                  it_behaves_like 'renders the product analytics dashboards'
                end
              end
            end
          end
        end
      end
    end
  end
end
