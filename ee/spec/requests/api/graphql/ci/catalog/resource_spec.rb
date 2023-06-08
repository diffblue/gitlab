# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.ciCatalogResource', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:user) { create(:user) }

  let_it_be(:project) do
    create(
      :project, :with_avatar,
      name: 'Component Repository',
      description: 'A simple component',
      namespace: namespace
    )
  end

  let_it_be(:resource) { create(:catalog_resource, project: project) }

  let(:query) do
    %(
      query {
        ciCatalogResource(id: "#{resource.to_global_id}") {
          id
          name
          description
          icon
        }
      }
    )
  end

  context 'when the CI Namespace Catalog feature is available' do
    before do
      stub_licensed_features(ci_namespace_catalog: true)
    end

    it 'returns requested resource' do
      namespace.add_developer(user)

      post_graphql(query, current_user: user)

      resource_data = graphql_data['ciCatalogResource']

      expect(resource_data['name']).to eq(project.name)
      expect(resource_data['description']).to eq(project.description)
      expect(resource_data['icon']).to eq(project.avatar_path)
    end

    context 'when the current user does not have permission to read the namespace catalog' do
      it 'returns nil' do
        namespace.add_guest(user)
        post_graphql(query, current_user: user)

        resources_data = graphql_data['ciCatalogResource']
        expect(resources_data).to be_nil
      end
    end
  end

  context 'when the CI Namespace Catalog feature is not available' do
    it 'returns nil' do
      namespace.add_developer(user)
      post_graphql(query, current_user: user)

      resources_data = graphql_data['ciCatalogResource']
      expect(resources_data).to be_nil
    end
  end
end
