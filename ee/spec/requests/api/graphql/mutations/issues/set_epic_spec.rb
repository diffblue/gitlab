# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting the epic of an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project, epic: create(:epic, group: group)) }
  let_it_be(:input) { { epic_id: global_id_of(epic) } }

  let(:mutation) do
    graphql_mutation(
      :issue_set_epic,
      { project_path: project.full_path, iid: issue.iid.to_s }.merge(input),
      <<~GRAPHQL
        clientMutationId
        errors
        issue {
          iid
          epic {
            iid
            title
          }
        }
      GRAPHQL
    )
  end

  def mutation_response
    graphql_mutation_response(:issue_set_epic)
  end

  before do
    project.add_developer(current_user)
    group.add_developer(current_user)
    stub_licensed_features(epics: true)
  end

  it 'returns an error if the user is not allowed to update the issue' do
    error = "The resource that you are attempting to access does not exist or you "\
            "don't have permission to perform this action"

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  it 'return an error if issue can not be updated' do
    issue.update_column(:author_id, nil)
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response["errors"]).to eq(["Author can't be blank"])
  end

  it 'sets given epic to the issue' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['issue']['epic']['iid']).to eq(epic.iid.to_s)
    expect(mutation_response['issue']['epic']['title']).to eq(epic.title)
    expect(issue.reload.epic).to eq(epic)
  end

  it 'removes existing epic if epic_id is nil' do
    input[:epic_id] = nil
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(issue.reload.epic).to be_nil
  end
end
