# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Runner EE (JavaScript fixtures)', feature_category: :runner_fleet do
  include StubVersion
  include AdminModeHelper
  include ApiHelpers
  include JavaScriptFixturesHelpers
  include GraphqlHelpers
  include RunnerReleasesHelper

  let_it_be(:admin) { create(:admin) }

  query_path = 'ci/runner/graphql/'
  fixtures_path = 'graphql/ci/runner/'

  describe 'as admin', GraphQL::Query do
    before do
      sign_in(admin)
      enable_admin_mode!(admin)
    end

    describe 'all_runners.query.graphql', type: :request do
      all_runners_query = 'list/all_runners.query.graphql'
      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{all_runners_query}")
      end

      let_it_be(:upgrade_available_runner) { create(:ci_runner, :instance, version: '15.0.0') }
      let_it_be(:upgrade_recommended_runner) { create(:ci_runner, :instance, version: '15.1.0') }
      let_it_be(:up_to_date_runner) { create(:ci_runner, :instance, version: '15.1.1') }

      before do
        stub_licensed_features(runner_upgrade_management: true)

        create(:ci_runner_version, version: upgrade_available_runner.version, status: :available)
        create(:ci_runner_version, version: upgrade_recommended_runner.version, status: :recommended)
        create(:ci_runner_version, version: up_to_date_runner.version, status: :unavailable)
        create(:ci_runner_machine, runner: upgrade_available_runner, version: upgrade_available_runner.version)
        create(:ci_runner_machine, runner: upgrade_recommended_runner, version: upgrade_recommended_runner.version)
        create(:ci_runner_machine, runner: up_to_date_runner, version: up_to_date_runner.version)
      end

      it "#{fixtures_path}#{all_runners_query}.upgrade_status.json" do
        post_graphql(query, current_user: admin, variables: {})

        expect_graphql_errors_to_be_empty
      end
    end

    describe 'most_active_runners.query.graphql', type: :request do
      runner_jobs_query = 'performance/most_active_runners.graphql'
      let_it_be(:query) do
        get_graphql_query_as_string("#{query_path}#{runner_jobs_query}", ee: true)
      end

      let_it_be(:runner) { create(:ci_runner, :instance, description: 'Runner 1') }
      let_it_be(:runner2) { create(:ci_runner, :instance, description: 'Runner 2') }

      let(:build) { create(:ci_build, :running, runner: runner) }
      let(:build2) { create(:ci_build, :running, runner: runner) }
      let(:build3) { create(:ci_build, :running, runner: runner2) }

      before do
        create(:ci_running_build, build: build,  runner: runner)
        create(:ci_running_build, build: build2, runner: runner)
        create(:ci_running_build, build: build3, runner: runner2)

        stub_licensed_features(runner_performance_insights: true)
      end

      it "#{fixtures_path}#{runner_jobs_query}.json" do
        post_graphql(query, current_user: admin)

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
