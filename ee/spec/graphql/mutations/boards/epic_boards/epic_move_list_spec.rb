# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Mutations::Boards::EpicBoards::EpicMoveList do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
  let(:epic) { create(:epic, group: group) }

  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:backlog) { create(:epic_list, epic_board: board, list_type: :backlog) }
  let_it_be(:labeled_list) { create(:epic_list, epic_board: board, label: development) }

  let(:current_ctx) { { current_user: current_user } }
  let(:params) do
    {
      board_id: board.to_global_id,
      epic_id: epic.to_global_id
    }
  end

  let(:move_params) do
    {
      from_list_id: backlog.to_global_id,
      to_list_id: labeled_list.to_global_id
    }
  end

  subject do
    sync(resolve(described_class, args: params.merge(move_params), ctx: current_ctx))
  end

  context 'arguments' do
    subject { described_class }

    it 'has the correct arguments' do
      expect(subject).to have_graphql_arguments(
        :boardId, :epicId, :fromListId, :toListId, :moveBeforeId, :moveAfterId, :positionInList
      )
    end
  end

  describe '#resolve' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when user does not have permissions' do
      it 'does not allow the move' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          subject
        end
      end
    end

    context 'when everything is ok' do
      before do
        group.add_developer(current_user)
      end

      it 'moves the epic to another list' do
        expect { subject }.to change { epic.reload.labels }.from([]).to([development])
      end
    end
  end
end
