# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Boards::EpicListsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:group) { create(:group, :private) }
  let_it_be_with_reload(:epic_board) { create(:epic_board, group: group) }
  let_it_be(:epic_list1) { create(:epic_list, epic_board: epic_board, list_type: :backlog) }
  let_it_be(:epic_list2) { create(:epic_list, epic_board: epic_board) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Boards::EpicListType.connection_type)
  end

  describe '#resolve' do
    let(:args) { {} }
    let(:resolver) { described_class }

    subject(:result) { resolve(resolver, ctx: { current_user: user }, obj: epic_board, args: args) }

    before do
      stub_licensed_features(epics: true)
    end

    it 'generates an error if user cannot read epic lists' do
      expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
        result
      end
    end

    context 'when user is member of the group' do
      before do
        group.add_reporter(user)
      end

      it 'returns epic lists for the board' do
        expect(result).to match_array([epic_list1, epic_list2])
      end

      context 'when resolving a single item' do
        let(:args) { { id: epic_list1.to_global_id } }
        let(:resolver) { described_class.single }

        it 'returns an array with single epic list' do
          expect(result).to eq(epic_list1)
        end
      end

      context 'when the board has hidden lists' do
        before do
          epic_board.update_column(:hide_backlog_list, true)
        end

        it 'returns an array with single epic list' do
          expect(result).to match_array(epic_list2)
        end
      end
    end
  end
end
