# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Boards::EpicListResolver do
  include GraphqlHelpers
  include Gitlab::Graphql::Laziness

  let_it_be(:guest)         { create(:user) }
  let_it_be(:unauth_user)   { create(:user) }
  let_it_be(:group)         { create(:group, :private) }
  let_it_be(:group_label)   { create(:group_label, group: group, name: 'Development') }
  let_it_be(:board)         { create(:epic_board, group: group) }
  let_it_be(:label_list)    { create(:epic_list, epic_board: board, label: group_label) }

  describe '#resolve' do
    subject { resolve_epic_board_list(args: { id: global_id_of(label_list) }, current_user: current_user) }

    before do
      stub_licensed_features(epics: true)
    end

    context 'with unauthorized user' do
      let(:current_user) { unauth_user }

      it 'raises unauthorized error' do
        expect { subject }.to raise_error(GraphQL::UnauthorizedError)
      end
    end

    context 'when authorized' do
      let(:current_user) { guest }

      before do
        group.add_guest(guest)
      end

      it { is_expected.to eq label_list }
    end
  end

  def resolve_epic_board_list(args: {}, current_user: user)
    force(resolve(described_class, obj: nil, args: args, ctx: { current_user: current_user }))
  end
end
