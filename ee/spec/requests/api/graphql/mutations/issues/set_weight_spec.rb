# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting weight of an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let(:current_user) { create(:user) }
  let(:issue) { create(:issue, weight: 1) }
  let(:project) { issue.project }
  let(:input) { { weight: 2 } }

  let(:mutation) do
    variables = {
      project_path: project.full_path,
      iid: issue.iid.to_s
    }
    graphql_mutation(:issue_set_weight, variables.merge(input),
                     <<-QL.strip_heredoc
                       clientMutationId
                       errors
                       issue {
                         iid
                         weight
                       }
                     QL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_set_weight)
  end

  before do
    project.add_developer(current_user)
  end

  it 'returns an error if the user is not allowed to update the issue' do
    error = "The resource that you are attempting to access does not exist or you "\
            "don't have permission to perform this action"

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  context 'when weight is a number' do
    it 'updates the issue weight' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']['weight']).to eq(2)
    end
  end

  context 'when weight is null' do
    let(:input) { { weight: nil } }

    it 'updates the issue weight' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(mutation_response['issue']['weight']).to eq(nil)
    end
  end

  context 'when weight is not an integer' do
    let(:input) { { weight: "2" } }

    it 'raises invalid value error' do
      error = "Variable $issueSetWeightInput of type IssueSetWeightInput! was provided "\
              "invalid value for weight (Could not coerce value \"#{input[:weight]}\" to Int)"

      post_graphql_mutation(mutation, current_user: current_user)

      expect(graphql_errors).to include(a_hash_including('message' => error))
    end
  end
end
