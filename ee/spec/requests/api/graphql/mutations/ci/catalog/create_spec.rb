# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'CatalogResourcesCreate', feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let(:mutation) do
    variables = {
      project_path: project.full_path
    }
    graphql_mutation(:catalog_resources_create, variables,
      <<-QL.strip_heredoc
                      errors
      QL
    )
  end

  before do
    stub_licensed_features(ci_namespace_catalog: true)
  end

  context 'when unauthorized' do
    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when authorized' do
    before do
      project.add_owner(current_user)
    end

    context 'with a valid project' do
      let_it_be(:project) { create(:project, :repository, description: 'our components') }

      it 'creates a catalog resource' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_mutation_response(:catalog_resources_create)['errors']).to be_empty
        expect(response).to have_gitlab_http_status(:success)
      end
    end

    context 'with an invalid project' do
      it 'returns an error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_mutation_response(:catalog_resources_create)['errors']).not_to be_empty
      end
    end
  end
end
