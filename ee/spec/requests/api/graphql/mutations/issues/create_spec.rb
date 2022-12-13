# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, namespace: group) }
  let_it_be(:cadence) { create(:iterations_cadence, group: group) }
  let_it_be(:current_iteration) { create(:iteration, iterations_cadence: cadence, start_date: 2.days.ago, due_date: 10.days.from_now) }

  let(:input) do
    {
      'title' => 'new title',
      'weight' => 2,
      'healthStatus' => 'atRisk',
      'iterationWildcardId' => 'CURRENT',
      'iterationCadenceId' => current_iteration.iterations_cadence.to_global_id.to_s
    }
  end

  let(:mutation) { graphql_mutation(:createIssue, input.merge('projectPath' => project.full_path)) }

  let(:mutation_response) { graphql_mutation_response(:create_issue) }

  before do
    stub_licensed_features(issuable_health_status: true, iterations: true)
    group.add_developer(current_user)
  end

  it 'creates the issue' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['issue']).to include(input.except('iterationWildcardId', 'iterationCadenceId'))
    expect(mutation_response['issue']).to include('iteration' => hash_including('id' => current_iteration.to_global_id.to_s))
  end

  context 'when iterationId is provided' do
    let(:input) do
      {
        'title' => 'new title',
        'weight' => 2,
        'healthStatus' => 'atRisk',
        'iterationId' => current_iteration.to_global_id.to_s
      }
    end

    it 'creates the issue' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']).to include(input.except('iterationId'))
      expect(mutation_response['issue']).to include('iteration' => hash_including('id' => current_iteration.to_global_id.to_s))
    end

    context 'when iterationId and iterationWildcardId are provided' do
      let(:input) do
        {
          'title' => 'new title',
          'weight' => 2,
          'healthStatus' => 'atRisk',
          'iterationId' => current_iteration.to_global_id.to_s,
          'iterationWildcardId' => 'CURRENT',
          'iterationCadenceId' => current_iteration.iterations_cadence.to_global_id.to_s
        }
      end

      it 'returns a mutually exclusive argument error' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(graphql_errors).to contain_exactly(hash_including('message' => 'Incompatible arguments: iterationId, iterationWildcardId.'))
      end
    end
  end
end
