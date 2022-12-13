# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update of an existing issue', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group) { create(:group) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:project) { create(:project, :public, group: group) }
  let_it_be(:issue, refind: true) { create(:issue, project: project) }

  let(:input) do
    {
      'iid' => issue.iid.to_s,
      'weight' => 2,
      'healthStatus' => 'atRisk'
    }
  end

  let(:mutation) { graphql_mutation(:update_issue, input.merge(project_path: project.full_path)) }
  let(:mutated_issue) { graphql_mutation_response(:update_issue)['issue'] }

  before do
    stub_licensed_features(issuable_health_status: true)
    project.add_reporter(current_user)
  end

  it 'updates the issue' do
    post_graphql_mutation(mutation, current_user: current_user)

    expect(response).to have_gitlab_http_status(:success)
    expect(mutated_issue).to include(input)
  end

  context 'setting epic' do
    let(:epic) { create(:epic, group: group) }

    let(:input) do
      { iid: issue.iid.to_s, epic_id: global_id_of(epic) }
    end

    before do
      stub_licensed_features(epics: true)
      group.add_guest(current_user)
    end

    it 'sets the epic' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_blank
      expect(mutated_issue).to include(
        'epic' => a_graphql_entity_for(epic)
      )
    end

    context 'the epic is not readable to the current user' do
      let(:epic) { create(:epic, :confidential, group: group) }

      it 'does not set the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to contain_exactly(
          a_hash_including('message' => /The resource that you are attempting to access does not exist/)
        )
      end
    end

    context 'the epic is not an epic' do
      let(:epic) { create(:user) }

      it 'does not set the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).not_to be_blank
      end
    end
  end

  context 'removing epic' do
    let(:epic) { create(:epic, group: group) }

    let(:input) do
      { iid: issue.iid.to_s, epic_id: nil }
    end

    before do
      stub_licensed_features(epics: true)
      group.add_guest(current_user)
      issue.update!(epic: epic)
    end

    it 'removes the epic' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(response).to have_gitlab_http_status(:success)
      expect(graphql_errors).to be_blank
      expect(mutated_issue).to include('epic' => be_nil)
    end

    context 'the epic argument is not provided' do
      let(:input) do
        { iid: issue.iid.to_s, weight: 1 }
      end

      it 'does not remove the epic' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(graphql_errors).to be_blank
        expect(mutated_issue).to include('epic' => be_present)
      end
    end
  end
end
