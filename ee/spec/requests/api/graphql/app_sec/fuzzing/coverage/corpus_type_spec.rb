# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Query.project(fullPath).corpuses', feature_category: :fuzz_testing do
  include GraphqlHelpers
  include StubRequests

  let_it_be(:corpus) { create(:corpus) }
  let_it_be(:project) { corpus.project }
  let_it_be(:user) { create(:user) }

  let_it_be(:query) do
    %(
      query {
        project(fullPath: "#{project.full_path}") {
          corpuses {
            nodes {
              id
              package {
                id
              }
            }
          }
        }
      }
    )
  end

  before do
    project.add_developer(user)
  end

  context 'when the user can read corpus for the project' do
    before do
      stub_licensed_features(coverage_fuzzing: true)
    end

    it 'returns corpus and package' do
      post_graphql(query, current_user: user)

      expect(response).to have_gitlab_http_status(:ok)

      nodes = graphql_data.dig('project', 'corpuses', 'nodes')
      expect(nodes).to contain_exactly({
        'id' => corpus.to_global_id.to_s, 'package' => { 'id' => corpus.package.to_global_id.to_s }
      })
    end
  end

  context 'when the user cannot read corpus for the project' do
    before do
      stub_licensed_features(coverage_fuzzing: false)
    end

    it 'returns nil' do
      post_graphql(query, current_user: user)

      expect(response).to have_gitlab_http_status(:ok)

      nodes = graphql_data.dig('project', 'corpuses', 'nodes')
      expect(nodes).to be_empty
    end
  end
end
