# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Create a milestone or assignee board list', feature_category: :team_planning do
  include GraphqlHelpers

  let_it_be(:group)     { create(:group, :private) }
  let_it_be(:board)     { create(:board, group: group) }
  let_it_be(:user)      { create(:user) }
  let_it_be(:guest)     { create(:user) }
  let_it_be(:milestone) { create(:milestone, group: group) }

  let(:current_user) { user }
  let(:mutation) { graphql_mutation(:board_list_create, input) }
  let(:mutation_response) { graphql_mutation_response(:board_list_create) }

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
  end

  context 'the user is not allowed to read board lists' do
    let(:input) { { board_id: board.to_global_id.to_s, milestone_id: milestone.to_global_id.to_s } }

    it_behaves_like 'a mutation that returns a top-level access error'
  end

  context 'when user has permissions to admin board lists' do
    before do
      group.add_reporter(current_user)
      group.add_guest(guest)
    end

    describe 'milestone list' do
      let(:input) { { board_id: board.to_global_id.to_s, milestone_id: milestone.to_global_id.to_s } }

      it 'creates the list' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['list'])
          .to include('position' => 0, 'listType' => 'milestone',
                      'milestone' => include('title' => milestone.title))
      end
    end

    describe 'assignee list' do
      let!(:input) { { board_id: board.to_global_id.to_s, assignee_id: guest.to_global_id.to_s } }

      it 'creates the list' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(response).to have_gitlab_http_status(:success)
        expect(mutation_response['list'])
          .to include('position' => 0, 'listType' => 'assignee',
                      'assignee' => include('id' => guest.to_global_id.to_s))
      end
    end
  end
end
