# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Deployments (JavaScript fixtures)' do
  include ApiHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:admin) { create(:admin, username: 'administrator', email: 'admin@example.gitlab.com') }
  let_it_be(:group) { create(:group, path: 'deployment-group') }
  let_it_be(:project) { create(:project, :repository, group: group, path: 'releases-project') }

  let_it_be(:environment) do
    create(:environment, project: project)
  end

  let_it_be(:protected_environment) { create(:protected_environment, name: environment.name, project: project) }
  let_it_be(:approval_group) do
    create(:protected_environment_approval_rule, group: group, protected_environment: protected_environment)
  end

  let_it_be(:approval_user) do
    create(:protected_environment_approval_rule, user: admin, protected_environment: protected_environment)
  end

  let_it_be(:approval_maintainer) do
    create(:protected_environment_approval_rule, :maintainer_access, protected_environment: protected_environment)
  end

  let_it_be(:approval_developer) do
    create(:protected_environment_approval_rule, :developer_access, protected_environment: protected_environment)
  end

  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:build) { create(:ci_build, :success, pipeline: pipeline) }

  let_it_be(:deployment) do
    create(:deployment, :success, environment: environment, deployable: build)
  end

  let_it_be(:approval) do
    create(:deployment_approval, user: admin, deployment: deployment, approval_rule: approval_group)
  end

  describe GraphQL::Query, type: :request do
    include GraphqlHelpers

    one_deployment_query_path = 'environments/graphql/queries/deployment.query.graphql'

    it "graphql/#{one_deployment_query_path}.json" do
      query = get_graphql_query_as_string(one_deployment_query_path, ee: true)

      post_graphql(query, current_user: admin, variables: { fullPath: project.full_path, iid: deployment.iid })

      expect_graphql_errors_to_be_empty
      expect(graphql_data_at(:project, :deployment)).to be_present
    end
  end
end
