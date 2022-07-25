# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Runner EE (JavaScript fixtures)' do
  include AdminModeHelper
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers

  let_it_be(:admin) { create(:admin) }

  query_path = 'runner/graphql/'
  fixtures_path = 'graphql/runner/'

  describe 'as admin', GraphQL::Query do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    describe 'all_runners.query.graphql', type: :request do
      let_it_be(:upgrade_available_runner) { create(:ci_runner, :instance, version: '15.0.0') }
      let_it_be(:upgrade_recommended_runner) { create(:ci_runner, :instance, version: '15.1.0') }
      let_it_be(:up_to_date_runner) { create(:ci_runner, :instance, version: '15.1.1') }

      all_runners_query = 'list/all_runners.query.graphql'

      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{all_runners_query}")
      end

      before do
        stub_licensed_features(runner_upgrade_management: true)

        stub_const('::Gitlab::VERSION', '15.1.0')
        available_runner_releases = %w[15.0.0 15.1.0 15.1.1]

        url = ::Gitlab::CurrentSettings.current_application_settings.public_runner_releases_url
        WebMock.stub_request(:get, url).to_return(
          body: available_runner_releases.map { |v| { name: v } }.to_json,
          status: 200,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it "#{fixtures_path}#{all_runners_query}.upgrade_status.json" do
        post_graphql(query, current_user: admin, variables: {})

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
