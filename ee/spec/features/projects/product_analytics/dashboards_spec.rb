# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Product Analytics Dashboard', :js, feature_category: :product_analytics do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:query_response_with_unknown_error) { fixture_file('cube_js/query_with_error.json', dir: 'ee') }
  let_it_be(:query_response_with_no_db_error) { fixture_file('cube_js/query_with_no_db_error.json', dir: 'ee') }
  let_it_be(:query_response_with_data) { fixture_file('cube_js/query_with_data.json', dir: 'ee') }

  let(:cube_api_url) { "https://cube.example.com/cubejs-api/v1/load" }

  before do
    stub_feature_flags(cube_api_proxy: true)
    project.add_owner(user)
    sign_in(user)
  end

  subject(:visit_page) { visit project_product_analytics_dashboards_path(project) }

  shared_examples 'renders product analytics 404' do
    before do
      visit_page
    end

    it do
      expect(page).to have_content(s_('404|Page Not Found'))
    end
  end

  shared_examples 'renders the onboarding view' do
    before do
      visit_page
    end

    it do
      expect(page).to have_content(s_('Product Analytics|Analyze your product with Product Analytics'))
    end
  end

  context 'without the required application settings' do
    it_behaves_like 'renders product analytics 404'
  end

  context 'with the required application settings' do
    before do
      stub_application_setting(product_analytics_enabled?: true)
      stub_application_setting(jitsu_host: 'https://jitsu.example.com')
      stub_application_setting(jitsu_project_xid: '123')
      stub_application_setting(jitsu_administrator_email: 'test@example.com')
      stub_application_setting(jitsu_administrator_password: 'password')
      stub_application_setting(clickhouse_connection_string: 'clickhouse://localhost:9000')
      stub_application_setting(cube_api_base_url: 'https://cube.example.com')
      stub_application_setting(cube_api_key: '123')
    end

    context 'with the feature flag disabled' do
      before do
        stub_feature_flags(product_analytics_internal_preview: false)
      end

      it_behaves_like 'renders product analytics 404'
    end

    context 'with the feature flag enabled' do
      before do
        stub_feature_flags(product_analytics_internal_preview: true)
      end

      context 'with the licensed feature disabled' do
        before do
          stub_licensed_features(product_analytics: false)
        end

        it_behaves_like 'renders product analytics 404'
      end

      context 'with the licensed feature enabled' do
        before do
          stub_licensed_features(product_analytics: true)
        end

        context 'without the Jitsu key' do
          it_behaves_like 'renders the onboarding view'
        end

        context 'with the Jitsu key' do
          before do
            project.project_setting.update!(jitsu_key: '123')
            project.reload
          end

          context 'when the cube API returns an unhandled error' do
            before do
              stub_cube_proxy_error
              visit_page
            end

            it 'renders the error alert' do
              error_msg = s_('ProductAnalytics|An error occurred while fetching data. Refresh the page to try again.')

              expect(find('[data-testid="alert-danger"]')).to have_text(error_msg)
            end
          end

          context 'when the clickhouse database does not exist' do
            before do
              stub_cube_no_database_error
            end

            it_behaves_like 'renders the onboarding view'
          end

          context 'when the cube API returns zero data' do
            before do
              stub_cube_proxy_zero_count
            end

            it_behaves_like 'renders the onboarding view'
          end

          context 'when the cube API returns data' do
            before do
              stub_cube_proxy_success
              visit_page
            end

            it 'renders the dashboards view' do
              expect(page).to have_content('All insights in one quick glance')
            end
          end
        end
      end
    end
  end

  private

  def stub_cube_proxy_error
    stub_request(:post, cube_api_url)
      .to_return(status: 200, body: query_response_with_unknown_error, headers: {})
  end

  def stub_cube_no_database_error
    stub_request(:post, cube_api_url)
      .to_return(status: 404, body: query_response_with_no_db_error, headers: {})
  end

  def stub_cube_proxy_zero_count
    query_object = Gitlab::Json.parse(query_response_with_data)
    query_object['results'][0]['data'][0]['Jitsu.count'] = 0

    stub_request(:post, cube_api_url)
      .to_return(status: 200, body: query_object.to_json, headers: {})
  end

  def stub_cube_proxy_success
    stub_request(:post, cube_api_url)
      .to_return(status: 200, body: query_response_with_data, headers: {})
  end
end
