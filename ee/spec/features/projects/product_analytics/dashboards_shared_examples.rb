# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'product analytics dashboards' do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:query_response_with_unknown_error) { fixture_file('cube_js/query_with_error.json', dir: 'ee') }
  let_it_be(:query_response_with_no_db_error) { fixture_file('cube_js/query_with_no_db_error.json', dir: 'ee') }
  let_it_be(:query_response_with_data) { fixture_file('cube_js/query_with_data.json', dir: 'ee') }

  let(:cube_api_url) { "https://cube.example.com/cubejs-api/v1/load" }

  shared_examples 'does not render the product analytics list item' do
    before do
      visit_page
    end

    it do
      expect(page).not_to have_content(_('Product Analytics'))
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

  shared_examples 'renders the setup view' do
    before do
      visit_page
    end

    it do
      expect(page).to have_content(s_('ProductAnalytics|Waiting for events'))
    end
  end

  context 'with the required application settings' do
    before do
      stub_application_setting(product_analytics_enabled?: true)
      stub_application_setting(product_analytics_configurator_connection_string: 'https://configurator.example.com')
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

      it_behaves_like 'does not render the product analytics list item'
    end

    context 'with the feature flag enabled' do
      before do
        stub_feature_flags(product_analytics_dashboards: true)
      end

      context 'with the licensed feature disabled' do
        before do
          stub_licensed_features(combined_project_analytics_dashboards: true, product_analytics: false)
        end

        it_behaves_like 'does not render the product analytics list item'
      end

      context 'with the licensed feature enabled' do
        before do
          stub_licensed_features(combined_project_analytics_dashboards: true, product_analytics: true)
        end

        context 'without the correct user permissions' do
          it_behaves_like 'does not render the product analytics list item'
        end

        context 'with the correct user permissions' do
          where(:project_setting, :snowplow_feature_flag_enabled) do
            { jitsu_key: 123 } | false
            { jitsu_key: 123 } | true
            { product_analytics_instrumentation_key: 456 } | true
          end

          with_them do
            before do
              project.add_maintainer(user)
              stub_feature_flags(product_analytics_snowplow_support: snowplow_feature_flag_enabled)
            end

            it 'renders the onboarding list item' do
              visit_page
              expect(page).to have_content(s_('Product Analytics'))
            end

            context 'when setting up a new instance' do
              before do
                visit_page
                wait_for_requests
                click_link _('Set up')
              end

              it 'renders the onboarding empty state' do
                expect(page).to have_content(s_('ProductAnalytics|Analyze your product with Product Analytics'))
              end

              it 'renders the creating instance loading screen and then the setup page' do
                click_button s_('ProductAnalytics|Set up product analytics')

                expect(page).to have_content(s_('ProductAnalytics|Creating your product analytics instance...'))

                wait_for_requests

                project.project_setting.update!(project_setting)
                project.reload

                stub_cube_proxy_zero_count
                ::ProductAnalytics::InitializeStackService.new(container: project).unlock!

                travel_to(1.minute.from_now) do
                  expect(page).to have_content(s_('ProductAnalytics|Instrument your application'))
                end
              end

              context 'and a new instance is already being intialized' do
                before do
                  ::ProductAnalytics::InitializeStackService.new(container: project).lock!
                end

                it 'renders an error alert when setting up a new instance' do
                  click_button s_('ProductAnalytics|Set up product analytics')

                  expect(find('[data-testid="alert-danger"]'))
                    .to have_text(/Product analytics initialization is already (completed|in progress)/)
                end
              end
            end

            context 'when the instance is loading' do
              before do
                project.project_setting.update!(project_setting)
                project.reload

                ::ProductAnalytics::InitializeStackService.new(container: project).lock!

                visit_page
                wait_for_requests
                click_link _('Set up')
              end

              it 'renders the loading view' do
                expect(page).to have_content(s_('ProductAnalytics|Creating your product analytics instance...'))
              end
            end

            context 'when waiting for events' do
              before do
                project.project_setting.update!(project_setting)
                project.reload

                ::ProductAnalytics::InitializeStackService.new(container: project).unlock!
              end

              context 'when the cube API returns an unhandled error' do
                before do
                  stub_cube_proxy_error
                  visit_page
                end

                it 'renders the error alert' do
                  error_msg =
                    s_('ProductAnalytics|An error occurred while fetching data. Refresh the page to try again.')

                  expect(find('[data-testid="alert-danger"]')).to have_text(error_msg)
                end
              end

              context 'when the clickhouse database does not exist' do
                before do
                  stub_cube_no_database_error
                  visit_page
                end

                it_behaves_like 'renders the setup view'
              end

              context 'when the cube API returns zero data' do
                before do
                  stub_cube_proxy_zero_count
                end

                it_behaves_like 'renders the setup view'
              end

              context 'when the cube API returns data' do
                before do
                  stub_cube_proxy_success
                  visit_page
                end

                it_behaves_like 'renders the product analytics dashboards'
              end

              context 'when the cube API returns data while onboarding' do
                before do
                  stub_cube_proxy_zero_count
                  visit_page
                end

                it 'renders the dashboard view after polling' do
                  travel_to(1.minute.from_now) do
                    expect(page).to have_content(s_('ProductAnalytics|Waiting for events'))
                  end

                  stub_cube_proxy_success

                  travel_to(1.minute.from_now) do
                    expect(page).to have_content('Understand your audience')
                  end
                end
              end
            end

            context 'with the setup completed' do
              before do
                project.project_setting.update!(project_setting)
                stub_cube_proxy_success
              end

              it_behaves_like 'renders the product analytics dashboards'

              context 'and custom dashboards is not configured' do
                it 'does not render the new dashboard button' do
                  visit_page

                  expect(page).not_to have_content(s_('Analytics|New dashboard'))
                end
              end

              context 'and custom dashboards is configured' do
                before do
                  create(:analytics_dashboards_pointer, :project_based, project: project)

                  visit_page
                end

                it 'renders the new dashboard button' do
                  expect(page).to have_content(s_('Analytics|New dashboard'))
                end
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
      query_object['results'][0]['data'][0]['TrackedEvents.count'] = 0

      stub_request(:post, cube_api_url)
        .to_return(status: 200, body: query_object.to_json, headers: {})
    end

    def stub_cube_proxy_success
      stub_request(:post, cube_api_url)
        .to_return(status: 200, body: query_response_with_data, headers: {})
    end
  end
end
