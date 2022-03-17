# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Boards::EpicBoardsResolver do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let_it_be_with_refind(:group) { create(:group, :private) }
  let_it_be(:epic_board1) { create(:epic_board, name: 'fooB', group: group) }
  let_it_be(:epic_board2) { create(:epic_board, name: 'fooA', group: group) }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Boards::EpicBoardType.connection_type)
  end

  describe '#resolve' do
    subject(:result) { resolve(described_class, ctx: { current_user: user }, obj: group) }

    context 'when epics are not available' do
      before do
        stub_licensed_features(epics: false)
      end

      it 'returns nil' do
        expect(result).to be_nil
      end
    end

    context 'when epics are available' do
      before do
        stub_licensed_features(epics: true)
      end

      it 'generates an error if user cannot read epic boards' do
        expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ResourceNotAvailable) do
          result
        end
      end

      context 'when user is member of the group' do
        before do
          group.add_reporter(user)
        end

        it 'returns epic boards in the group ordered by name' do
          expect(result)
            .to contain_exactly(epic_board2, epic_board1)
            .and be_sorted.asc.by(&:name)
        end
      end
    end
  end
end
