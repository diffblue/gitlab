# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Analytics Visualization Designer', :js, feature_category: :product_analytics do
  let_it_be(:current_user) { create(:user) }
  let_it_be(:user) { current_user }
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:meta_response_with_data) { fixture_file('cube_js/meta_with_data.json', dir: 'ee') }
  let_it_be(:query_response_with_data) { fixture_file('cube_js/query_with_data.json', dir: 'ee') }
  let_it_be(:query_response_with_error) { fixture_file('cube_js/query_with_error.json', dir: 'ee') }

  let(:cube_meta_api_url) { "https://cube.example.com/cubejs-api/v1/meta" }
  let(:cube_dry_run_api_url) { "https://cube.example.com/cubejs-api/v1/dry-run" }
  let(:cube_load_api_url) { "https://cube.example.com/cubejs-api/v1/load" }

  subject(:visit_page) do
    visit project_analytics_dashboards_path(project)
    click_link "Visualization Designer"
  end

  context 'with all required access and analytics settings configured' do
    before do
      sign_in(user)
      stub_feature_flags(combined_analytics_dashboards: true, product_analytics_dashboards: true)
      stub_licensed_features(combined_project_analytics_dashboards: true, product_analytics: true)

      stub_application_setting(product_analytics_enabled?: true)
      stub_application_setting(jitsu_host: 'https://jitsu.example.com')
      stub_application_setting(jitsu_project_xid: '123')
      stub_application_setting(jitsu_administrator_email: 'test@example.com')
      stub_application_setting(jitsu_administrator_password: 'password')
      stub_application_setting(product_analytics_data_collector_host: 'https://collector.example.com')
      stub_application_setting(product_analytics_clickhouse_connection_string: 'clickhouse://localhost:9000')
      stub_application_setting(cube_api_base_url: 'https://cube.example.com')
      stub_application_setting(cube_api_key: '123')

      project.add_developer(user)
      project.project_setting.update!(jitsu_key: '123')
      project.reload

      stub_request(:get, cube_meta_api_url)
        .to_return(status: 200, body: meta_response_with_data, headers: {})
    end

    context 'with valid data' do
      before do
        stub_request(:post, cube_dry_run_api_url)
          .to_return(status: 200, body: query_response_with_data, headers: {})
        stub_request(:post, cube_load_api_url)
          .to_return(status: 200, body: query_response_with_data, headers: {})
      end

      it 'renders the measure selection, preview, and visualization selection panels' do
        visit_page

        expect(page).to have_content('What do you want to measure?')
        expect(page).to have_content('Choose a measurement to start')
        expect(page).to have_content('Visualization Type')
      end

      context 'with a measure selected' do
        before do
          visit_page
          select_all_views_measure
        end

        it 'shows the selected measure data' do
          expect(find('[data-testid="grid-stack-panel"]')).to have_content('Tracked Events.count 335')
        end

        [
          {
            name: 'LineChart',
            button_text: 'Line Chart',
            content: 'TrackedEvents Count Avg: 335 · Max: 335'
          },
          {
            name: 'ColumnChart',
            button_text: 'Column Chart',
            selector: 'dashboard-visualization-column-chart'
          },
          {
            name: 'DataTable',
            button_text: 'Data Table',
            content: 'Count 335'
          },
          {
            name: 'SingleStat',
            button_text: 'Single Statistic',
            content: '335'
          }
        ].each do |visualization|
          context "with #{visualization[:button_text]} visualization selected" do
            before do
              click_button visualization[:button_text]
            end

            it "shows the #{visualization[:button_text]} preview" do
              preview_panel = find('[data-testid="preview-visualization"]')

              if visualization[:content].nil?
                expect(preview_panel).to have_selector("[data-testid=\"#{visualization[:selector]}\"]")
              else
                expect(preview_panel).to have_content(visualization[:content])
              end
            end

            context 'with the code tab selected' do
              before do
                click_button 'Code'
              end

              it 'shows the visualization code' do
                json_snippet = "\"type\": \"#{visualization[:name]}\","
                expect(find('[data-testid="preview-code"]')).to have_content(json_snippet)
              end
            end
          end
        end
      end
    end

    context 'when data fails to load' do
      it 'shows error when selecting a measure fails' do
        stub_request(:post, cube_dry_run_api_url)
          .to_return(status: 200, body: query_response_with_error, headers: {})
        stub_request(:post, cube_load_api_url)
          .to_return(status: 200, body: query_response_with_error, headers: {})

        visit_page
        select_all_views_measure

        expect(page).to have_content('An error occurred while loading data')
      end
    end
  end

  def select_all_views_measure
    click_button 'Page Views'
    click_button 'All Pages'
  end
end
