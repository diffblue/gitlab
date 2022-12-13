# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Setting the epic of an issue', feature_category: :team_planning do
  include GraphqlHelpers

  let(:new_epic_group) { nil }

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:user) { create(:user) }

  let(:input) { { group_path: new_epic_group&.full_path } }

  let(:mutation) do
    graphql_mutation(
      :promote_to_epic,
      { project_path: project.full_path, iid: issue.iid.to_s }.merge(input),
      <<~GRAPHQL
        clientMutationId
        errors
        issue {
          iid
          title
          state
        }
        epic {
          id
          title
          group {
            id
          }
        }
    GRAPHQL
    )
  end

  def mutation_response
    graphql_mutation_response(:promote_to_epic)
  end

  before_all do
    project.add_developer(current_user)
    group.add_developer(current_user)
  end

  before do
    stub_licensed_features(epics: true)
    # todo: investigate too many qeuries issue as part of Project Management Database and Query Performance
    # epic: https://gitlab.com/groups/gitlab-org/-/epics/5804
    # specific issue: https://gitlab.com/gitlab-org/gitlab/-/issues/333845
    allow(Gitlab::QueryLimiting::Transaction).to receive(:threshold).and_return(110)
  end

  it 'returns an error if the user is not allowed to update the issue' do
    error = "The resource that you are attempting to access does not exist or you "\
            "don't have permission to perform this action"

    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => error))
  end

  it 'returns an error if issue can not be updated' do
    issue.update_column(:author_id, nil)
    post_graphql_mutation(mutation, current_user: current_user)

    expect(mutation_response["errors"]).to eq(["Author can't be blank"])
  end

  it 'promotes the issue to epic' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutation_response['errors']).to be_empty
    expect(mutation_response['issue']['state']).to eq('closed')
    expect(mutation_response['epic']['title']).to eq(issue.title)
    expect(mutation_response['epic']['group']['id']).to eq(group.to_global_id.to_s)
    expect(issue.reload.promoted_to_epic_id.to_s).to eq(GlobalID.parse(mutation_response['epic']['id']).model_id)
  end

  context 'when epic has to be in a different group' do
    let(:new_epic_group) { create(:group) }

    context 'when user cannot create epic in new group' do
      it 'does not promote the issue to epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['issue']['state']).to eq('opened')
        expect(mutation_response['errors']).not_to be_empty
        expect(mutation_response['errors']).to eq(['Cannot promote issue due to insufficient permissions.'])
      end
    end

    context 'when user can create epic in new group' do
      before do
        new_epic_group.add_developer(current_user)
      end

      it 'promotes the issue to epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['errors']).to be_empty
        expect(mutation_response['issue']['state']).to eq('closed')
        expect(mutation_response['epic']['title']).to eq(issue.title)
        expect(mutation_response['epic']['group']['id']).to eq(new_epic_group.to_global_id.to_s)
        expect(issue.reload.promoted_to_epic_id.to_s).to eq(GlobalID.parse(mutation_response['epic']['id']).model_id)
      end
    end
  end
end
