# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Code Quality Report (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:current_user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, :success, :with_codequality_reports, project: project) }

    codequality_report_query_path = 'codequality_report/graphql/queries/get_code_quality_violations.query.graphql'

    it "graphql/#{codequality_report_query_path}.json" do
      project.add_developer(current_user)

      query = get_graphql_query_as_string(codequality_report_query_path, ee: true)

      post_graphql(query, current_user: current_user, variables: { projectPath: project.full_path, iid: pipeline.iid })

      expect_graphql_errors_to_be_empty
    end
  end
end
