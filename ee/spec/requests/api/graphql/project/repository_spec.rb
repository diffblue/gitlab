# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'getting a repository in a project', feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }

  let(:current_user) { project.first_owner }
  let(:code_owners_path_args) { {} }
  let(:code_owners_path_data) { graphql_data.dig('project', 'repository', 'codeOwnersPath') }
  let(:query) do
    graphql_query_for(
      :project, { full_path: project.full_path }, query_graphql_field(
        :repository, {}, field_with_params(
          :code_owners_path, code_owners_path_args
        )
      )
    )
  end

  before do
    post_graphql(query, current_user: current_user)
  end

  context 'when ref arg is omitted' do
    it 'returns the CODEOWNERS file from the default branch' do
      expect(code_owners_path_data).to be_nil
    end
  end

  context 'when ref arg is invalid' do
    let(:code_owners_path_args) { { ref: '' } }

    it 'returns an error' do
      expect(graphql_errors).to be_present
    end
  end

  context 'when ref arg is passed' do
    let(:code_owners_path_args) { { ref: 'with-codeowners' } }

    it 'returns the CODEOWNERS file from the requested branch' do
      expect(code_owners_path_data)
        .to eq("/#{project.full_path}/-/blob/with-codeowners/docs/CODEOWNERS")
    end
  end
end
