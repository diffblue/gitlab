# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Epics::CreateService do
  let_it_be(:user) { create(:user) }
  let_it_be(:parent_group) { create(:group) }
  let_it_be(:group) { create(:group, parent: parent_group) }
  let_it_be(:board) { create(:epic_board, group: group) }

  describe '#execute' do
    let_it_be(:development) { create(:group_label, group: group, name: 'Development') }

    let_it_be(:backlog) { create(:epic_list, epic_board: board, list_type: :backlog) }
    let_it_be(:list) { create(:epic_list, epic_board: board, label: development, position: 0) }

    let(:valid_params) do
      { board_id: board.id, list_id: list.id, title: 'Gilgamesh' }
    end

    let(:params) { valid_params }

    subject(:response) do
      described_class.new(group, user, params).execute
    end

    shared_examples 'epic creation error' do |error_pattern|
      it 'does not create epic' do
        expect(response).to be_error
        expect(response.message).to match(error_pattern)
      end
    end

    shared_examples 'success epic creation' do
      it 'creates an epic' do
        expect(response).to be_success
        expect(response.payload).to be_a(Epic)
      end

      specify { expect { subject }.to change { Epic.count }.by(1) }
    end

    context 'when epics feature is available' do
      before do
        stub_licensed_features(epics: true)
        group.add_developer(user)
      end

      it_behaves_like 'success epic creation'

      context 'when board is in an ancestor group' do
        let_it_be(:parent_board) { create(:epic_board, group: parent_group) }
        let_it_be(:parent_list) { create(:epic_list, epic_board: parent_board) }

        let(:params) { valid_params.merge(board_id: parent_board.id, list_id: parent_list.id) }

        it_behaves_like 'success epic creation'
      end

      context 'when arguments are not valid' do
        let_it_be(:other_board) { create(:epic_board) }
        let_it_be(:other_board_list) { create(:epic_list, epic_board: other_board) }

        context 'when board id is bogus' do
          let(:params) { valid_params.merge(board_id: non_existing_record_id) }

          it_behaves_like 'epic creation error', /Board not found/
        end

        context 'when list id is for a different board' do
          let(:params) { valid_params.merge(list_id: other_board_list.id) }

          it_behaves_like 'epic creation error', /List not found/
        end

        context 'when board id is for a different group' do
          let(:params) { valid_params.merge(board_id: other_board.id) }

          it_behaves_like 'epic creation error', /Board not found/
        end
      end
    end

    context 'when epics feature is not available' do
      it_behaves_like 'epic creation error', 'This feature is not available'
    end
  end
end
