# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'On-demand DAST scans (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:current_user) { create(:user) }
    let_it_be(:project) { create(:project, :repository, :public) }
    let_it_be(:dast_profile) { create(:dast_profile, project: project) }

    before do
      stub_licensed_features(security_on_demand_scans: true)
      project.add_developer(current_user)
    end

    context 'project on demand scans count' do
      path = 'on_demand_scans/graphql/on_demand_scan_counts.query.graphql'

      let_it_be(:pipelines) do
        [
          create(:ci_pipeline, :success, source: :ondemand_dast_scan, sha: project.commit.id, project: project, user: current_user),
          create(:ci_pipeline, :failed, source: :ondemand_dast_scan, sha: project.commit.id, project: project, user: current_user),
          create(:ci_pipeline, :running, source: :ondemand_dast_scan, sha: project.commit.id, project: project, user: current_user),
          create(:ci_pipeline, :running, source: :ondemand_dast_scan, sha: project.commit.id, project: project, user: current_user)
        ]
      end

      it "graphql/#{path}.json" do
        query = get_graphql_query_as_string(path, ee: true)

        post_graphql(query, current_user: current_user, variables: {
          fullPath: project.full_path,
          runningScope: 'RUNNING',
          finishedScope: 'FINISHED'
        })

        expect_graphql_errors_to_be_empty
        expect(graphql_data_at(:project, :pipelineCounts, :all)).to be(4)
        expect(graphql_data_at(:project, :pipelineCounts, :running)).to be(2)
        expect(graphql_data_at(:project, :pipelineCounts, :finished)).to be(2)
      end
    end

    context 'pipelines list' do
      path = 'on_demand_scans/graphql/on_demand_scans.query.graphql'

      context 'with pipelines' do
        let_it_be(:pipelines) do
          create_list(
            :ci_pipeline,
            30,
            :success,
            source: :ondemand_dast_scan,
            sha: project.commit.id,
            project: project,
            user: current_user,
            dast_profile: dast_profile
          )
        end

        it "graphql/#{path}.with_pipelines.json" do
          query = get_graphql_query_as_string(path, ee: true)

          post_graphql(query, current_user: current_user, variables: {
            fullPath: project.full_path,
            first: 20
          })

          expect_graphql_errors_to_be_empty
          expect(graphql_data_at(:project, :pipelines, :nodes)).to have_attributes(size: 20)
        end
      end

      context 'without pipelines' do
        it "graphql/#{path}.without_pipelines.json" do
          query = get_graphql_query_as_string(path, ee: true)

          post_graphql(query, current_user: current_user, variables: {
            fullPath: project.full_path,
            first: 20
          })

          expect_graphql_errors_to_be_empty
          expect(graphql_data_at(:project, :pipelines, :nodes)).to be_empty
        end
      end
    end
  end
end
