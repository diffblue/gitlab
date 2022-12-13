# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::EpicBoards::Destroy, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be_with_reload(:current_user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:other_board, refind: true) { create(:epic_board, group: group) }

  let(:mutation) do
    variables = {
      id: board.to_global_id.to_s
    }

    graphql_mutation(:destroy_epic_board, variables)
  end

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:destroy_epic_board)
  end

  before do
    stub_licensed_features(epics: true)
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not destroy the board' do
      expect { subject }.not_to change { ::Boards::EpicBoard.count }
    end
  end

  context 'when the user has permission' do
    before do
      group.add_developer(current_user)
    end

    context 'when everything is ok' do
      it 'destroys the board' do
        expect { subject }.to change { ::Boards::EpicBoard.count }.by(-1)
      end

      it 'returns an empty board' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to have_key('epicBoard')
        expect(mutation_response['epicBoard']).to be_nil
      end
    end

    context 'when there is only 1 board for the parent' do
      before do
        other_board.destroy!
      end

      it 'does destroy the board' do
        expect { subject }.to change { ::Boards::EpicBoard.count }.by(-1)
      end
    end
  end
end
