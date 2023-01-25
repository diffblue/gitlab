# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::EpicBoardPosition, feature_category: :portfolio_management do
  let_it_be(:epic) { create(:epic) }
  let_it_be(:group) { create(:group) }
  let_it_be(:epic_board) { create(:epic_board, group: group) }
  let_it_be(:epic_board_position) { create(:epic_board_position, epic: epic, epic_board: epic_board) }

  describe 'associations' do
    subject { build(:epic_board_position) }

    it { is_expected.to belong_to(:epic).required }
    it { is_expected.to belong_to(:epic_board).required.inverse_of(:epic_board_positions) }
  end

  describe 'validations' do
    subject { build(:epic_board_position) }

    specify { expect(subject).to be_valid }

    it 'is valid with nil relative position' do
      subject.relative_position = nil

      expect(subject).to be_valid
    end

    it 'disallows a record with same epic and board' do
      expect(build(:epic_board_position, epic: epic, epic_board: epic_board)).not_to be_valid
    end
  end

  describe 'scopes' do
    describe '.order_relative_position' do
      let(:first) { epic_board_position }
      let!(:second) { create(:epic_board_position, epic_board: epic_board, relative_position: RelativePositioning::START_POSITION + 7 ) }

      it 'returns epic_board_positions in order' do
        expect(described_class.order_relative_position).to eq([first, second])
      end
    end
  end

  describe '.last_for_board_id' do
    let_it_be(:position1) { create(:epic_board_position, relative_position: 1, epic_board: epic_board) }
    let_it_be(:position2) { create(:epic_board_position, relative_position: 1900, epic_board: epic_board) }
    let_it_be(:position3) { create(:epic_board_position, relative_position: 4000) }
    let_it_be(:position4) { create(:epic_board_position, epic_board: epic_board, relative_position: nil) }

    it 'returns highest not null position' do
      expect(described_class.last_for_board_id(epic_board.id)).to eq(position2)
    end
  end

  context 'relative positioning' do
    let_it_be(:positioning_group) { create(:group) }
    let_it_be(:positioning_board) { create(:epic_board, group: positioning_group) }

    it_behaves_like "a class that supports relative positioning" do
      let(:factory) { :epic_board_position }
      let(:default_params) { { parent: positioning_board } }
    end
  end
end
