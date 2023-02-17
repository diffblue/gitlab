# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Project Quality Summary (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers
    include TestReportsHelper

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, :with_test_reports, :with_codequality_reports, :with_report_results, project: project) }

    let!(:coverage) { create(:ci_build, :success, pipeline: pipeline, coverage: 78) }
    let!(:build) { create(:ci_build, pipeline: pipeline) }
    let!(:report_result) { create(:ci_build_report_result, :with_junit_success, build: build) }

    project_quality_summary_query_path = 'project_quality_summary/graphql/queries/get_project_quality.query.graphql'

    it "graphql/#{project_quality_summary_query_path}.json" do
      project.add_developer(current_user)

      query = get_graphql_query_as_string(project_quality_summary_query_path, ee: true)

      post_graphql(query, current_user: current_user, variables: { projectPath: project.full_path, defaultBranch: project.default_branch })

      expect_graphql_errors_to_be_empty
    end
  end
end
