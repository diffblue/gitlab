# frozen_string_literal: true

require 'spec_helper'

RSpec.describe "GraphQL CI/CD catalog resources", '(JavaScript fixtures)', type: :request, feature_category: :pipeline_composition do
  include ApiHelpers
  include GraphqlHelpers
  include JavaScriptFixturesHelpers

  let_it_be(:namespace) { create(:group, name: 'frontend-fixtures') }
  let_it_be(:project) { create(:project, :public, namespace: namespace) }
  let_it_be(:current_user) { create(:user) }

  query_name = 'ci_catalog_resources'
  get_ci_catalog_resources = "ci/catalog/graphql/queries/get_#{query_name}.query.graphql"

  before_all do
    namespace.add_developer(current_user)
  end

  before do
    stub_licensed_features(ci_namespace_catalog: true)
  end

  context 'when there are no CI Catalog resources' do
    it "graphql/ci/catalog/#{query_name}_empty.json" do
      query = get_graphql_query_as_string(get_ci_catalog_resources, ee: true)

      post_graphql(query, current_user: current_user, variables: { fullPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'when there is a single page of CI Catalog resources' do
    let(:projects) do
      create_list(
        :project,
        3,
        description: 'A simple component',
        namespace: namespace
      )
    end

    before do
      projects.each do |current_project|
        create(:catalog_resource, project: current_project)
      end
    end

    it "graphql/ci/catalog/#{query_name}_single_page.json" do
      query = get_graphql_query_as_string(get_ci_catalog_resources, ee: true)

      post_graphql(query, current_user: current_user, variables: { fullPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end
  end

  context 'when there are multiple pages of CI Catalog resources' do
    # rubocop:disable RSpec/FactoryBot/ExcessiveCreateList because we
    # need a minimum of 3 pages to test pagination and each page is 20 items long.
    let(:projects) do
      create_list(
        :project,
        41,
        description: 'A simple component',
        namespace: namespace
      )
    end
    # rubocop:enable RSpec/FactoryBot/ExcessiveCreateList

    before do
      projects.each do |current_project|
        create(:catalog_resource, project: current_project)
      end
    end

    it "graphql/ci/catalog/#{query_name}.json" do
      query = get_graphql_query_as_string(get_ci_catalog_resources, ee: true)

      post_graphql(query, current_user: current_user, variables: { fullPath: project.full_path })

      expect_graphql_errors_to_be_empty
    end
  end
end
