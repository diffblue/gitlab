# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::EpicBoard do
  describe 'associations' do
    it { is_expected.to belong_to(:group).required.inverse_of(:epic_boards) }
    it { is_expected.to have_many(:epic_board_labels).inverse_of(:epic_board) }
    it { is_expected.to have_many(:epic_board_positions).inverse_of(:epic_board) }
    it { is_expected.to have_many(:epic_board_recent_visits).inverse_of(:epic_board) }
    it { is_expected.to have_many(:epic_lists).order(list_type: :asc, position: :asc).inverse_of(:epic_board) }

    it do
      is_expected.to have_many(:destroyable_lists).class_name('EpicList')
        .order(list_type: :asc, position: :asc).inverse_of(:epic_board)
    end
  end

  describe 'validations' do
    it { is_expected.to validate_length_of(:name).is_at_most(255) }
  end

  describe 'scopes' do
    let_it_be(:board1) { create(:epic_board, name: 'B') }
    let_it_be(:board2) { create(:epic_board, name: 'a') }
    let_it_be(:board3) { create(:epic_board, name: 'A') }

    describe '.order_by_name_asc' do
      it 'returns in case-insensitive alphabetical order and then by ascending ID' do
        expect(described_class.order_by_name_asc).to eq [board2, board3, board1]
      end
    end

    describe '.for_groups' do
      it 'returns boards only in selected groups' do
        expect(described_class.for_groups([board1.group_id, board2.group_id])).to match_array([board1, board2])
      end
    end
  end
end
