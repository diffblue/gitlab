# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogResources', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project_2) { create(:project, namespace: namespace) }
  let_it_be(:resource_2) { create(:catalog_resource, project: project_2) }
  let_it_be(:user) { create(:user) }

  let_it_be(:project_1) do
    create(
      :project, :with_avatar,
      name: 'Component Repository',
      description: 'A simple component',
      namespace: namespace
    )
  end

  let_it_be(:resource_1) { create(:catalog_resource, project: project_1) }

  let(:query) do
    %(
      query {
        ciCatalogResources(projectPath: "#{project_2.full_path}") {
          count

          nodes {
            name
            description
            icon
          }
        }
      }
    )
  end

  context 'when the CI Namespace Catalog feature is available' do
    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    it 'returns all resources visible to the current user in the namespace' do
      namespace.add_developer(user)

      post_graphql(query, current_user: user)

      resources_data = graphql_data['ciCatalogResources']
      expect(resources_data['count']).to be(2)
      expect(resources_data['nodes'].count).to be(2)

      resource_1_data = resources_data['nodes'].first
      expect(resource_1_data['name']).to eq('Component Repository')
      expect(resource_1_data['description']).to eq('A simple component')
      expect(resource_1_data['icon']).to eq(project_1.avatar_path)
    end

    context 'when the current user does not have permission to read the namespace catalog' do
      it 'returns an empty array' do
        namespace.add_guest(user)

        post_graphql(query, current_user: user)

        resources_data = graphql_data['ciCatalogResources']
        expect(resources_data).to be_nil
      end
    end
  end

  context 'when the CI Namespace Catalog feature is not available' do
    it 'returns an empty array' do
      namespace.add_developer(user)

      post_graphql(query, current_user: user)

      resources_data = graphql_data['ciCatalogResources']
      expect(resources_data).to be_nil
    end
  end
end
