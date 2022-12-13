# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Epics::Create, feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user, reload: true) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:list) { create(:epic_list, epic_board: board) }

  let(:params) do
    {
      group_path: group.full_path,
      board_id: global_id_of(board),
      list_id: global_id_of(list),
      title: title
    }
  end

  let(:title) { 'The Odyssey' }
  let(:mutation) { graphql_mutation(:board_epic_create, params) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:board_epic_create)
  end

  shared_examples 'does not create an epic' do
    specify do
      expect { subject }.not_to change { Board.count }
    end
  end

  context 'when the user does not have permission' do
    it_behaves_like 'a mutation that returns a top-level access error'

    it_behaves_like 'does not create an epic'
  end

  context 'when the user has permission' do
    before do
      group.add_reporter(current_user)
      stub_licensed_features(epics: true)
    end

    context 'when all arguments are given' do
      context 'when everything is ok' do
        it 'creates the epic' do
          expect { subject }.to change { Epic.count }.from(0).to(1)
        end

        it 'returns the created epic' do
          subject

          expect(mutation_response).to have_key('epic')
          expect(mutation_response['epic']['title']).to eq(title)
        end
      end

      context 'when arguments are nil resulting in a top level error' do
        before do
          params[:board_id] = nil
        end

        it_behaves_like 'does not create an epic'

        it_behaves_like 'a mutation that returns top-level errors' do
          let(:match_errors) { include(/boardId \(Expected value to not be null\)/) }
        end
      end

      context 'when argument is blank resulting in an ActiveRecord error' do
        before do
          params[:title] = ""
        end

        it_behaves_like 'does not create an epic'

        it 'returns an error' do
          subject

          expect(mutation_response['epic']).to be_nil
          expect(mutation_response['errors'].first).to eq("Title can't be blank")
        end
      end
    end

    context 'when arguments are missing' do
      let(:params) { { title: title } }

      it_behaves_like 'a mutation that returns top-level errors' do
        let(:match_errors) { include(/boardId \(Expected value to not be null\)/) }
      end

      it_behaves_like 'does not create an epic'
    end
  end
end
