# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Update board epic user preferences', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:user)  { create(:user) }
  let_it_be(:epic)  { create(:epic, group: group) }

  let(:mutation_class) { Mutations::Boards::UpdateEpicUserPreferences }
  let(:mutation_name) { mutation_class.graphql_name }
  let(:mutation_result_identifier) { mutation_name.camelize(:lower) }

  let(:mutation) do
    params = {
      epic_id: epic.to_global_id.to_s,
      board_id: board.to_global_id.to_s,
      collapsed: true
    }

    graphql_mutation(mutation_name, params,
                     <<-QL.strip_heredoc
                       clientMutationId
                       epicUserPreferences {
                         collapsed
                       }
                       errors
    QL
    )
  end

  it 'returns an error if user can not access the board' do
    post_graphql_mutation(mutation, current_user: create(:user))

    expect(graphql_errors).to include(a_hash_including('message' => "The resource that you are attempting to access does " \
     "not exist or you don't have permission to perform this action"))
  end

  context 'when user can access the board' do
    before do
      group.add_developer(user)
    end

    it 'returns an error if user can not access the epic' do
      post_graphql_mutation(mutation, current_user: create(:user))

      expect(graphql_errors).to include(a_hash_including('message' => "The resource that you are attempting to access does " \
       "not exist or you don't have permission to perform this action"))
    end

    context 'when user can access the epic' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'updates user preferences' do
        post_graphql_mutation(mutation, current_user: user)

        expect(response).to have_gitlab_http_status(:success)

        preferences = json_response['data'][mutation_result_identifier]
        expect(preferences['epicUserPreferences']['collapsed']).to be_truthy
      end
    end
  end
end
