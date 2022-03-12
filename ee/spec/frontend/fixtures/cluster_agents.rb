# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Cluster agents (GraphQL fixtures)' do
  describe GraphQL::Query, type: :request do
    include ApiHelpers
    include GraphqlHelpers
    include JavaScriptFixturesHelpers

    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:current_user) { create(:user) }

    context 'cluster_agents.query.graphql' do
      path = 'security_dashboard/graphql/queries/cluster_agents.query.graphql'

      it "graphql/#{path}.json" do
        project.add_developer(current_user)

        query = get_graphql_query_as_string(path, ee: true)

        post_graphql(query, current_user: current_user, variables: { projectPath: project.full_path })

        expect_graphql_errors_to_be_empty
      end
    end
  end
end
