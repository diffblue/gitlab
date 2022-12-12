# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Epics::PositionCreateService, feature_category: :portfolio_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:list)  { create(:epic_list, epic_board: board, list_type: :backlog) }

  let_it_be_with_reload(:epic1) { create(:epic, group: group) }
  let_it_be_with_reload(:epic2) { create(:epic, group: group) }
  let_it_be_with_reload(:epic3) { create(:epic, group: group) }
  let_it_be_with_reload(:epic4) { create(:epic, group: group) }
  let_it_be(:epic_other_group) { create(:epic, group: create(:group)) }

  let(:params) { { board_id: board.id, list_id: list.id } }

  describe '#execute' do
    before do
      stub_licensed_features(epics: true)
      group.add_developer(user)
    end

    context 'with invalid params' do
      it 'raises an error when board_id is missing' do
        expect { described_class.new(group, user, { list_id: list.id }).execute }
          .to raise_error(ArgumentError, 'board_id param is missing')
      end

      it 'raises an error when list_id is missing' do
        expect { described_class.new(group, user, { board_id: board.id }).execute }
          .to raise_error(ArgumentError, 'list_id param is missing')
      end
    end

    context 'with correct params' do
      subject { described_class.new(group, user, params).execute }

      let(:ordered_by_relative_position) { Boards::EpicBoardPosition.order(:relative_position) }

      let_it_be(:ideal_distance) { Boards::EpicBoardPosition::IDEAL_DISTANCE }

      context 'without additional params' do
        context 'when there are no positions' do
          it 'creates the positions for all epics in the list' do
            expect { subject }.to change { Boards::EpicBoardPosition.count }.by(4)
          end

          it 'sets the relative_position based on id' do
            subject

            expect(ordered_by_relative_position.map(&:epic_id)).to eq([epic4.id, epic3.id, epic2.id, epic1.id])
            expect(ordered_by_relative_position.map(&:relative_position))
              .to eq([ideal_distance * 2, ideal_distance * 3, ideal_distance * 4, ideal_distance * 5])
          end
        end

        context 'when some positions exist' do
          context 'when there is still space for new positions' do
            let_it_be(:epic_position1) { create(:epic_board_position, epic: epic1, epic_board: board, relative_position: 1000) }
            let_it_be(:epic_position3) { create(:epic_board_position, epic: epic3, epic_board: board, relative_position: 10) }

            it 'creates the positions for non existing epics in the list' do
              expect { subject }.to change { Boards::EpicBoardPosition.count }.by(2)
            end

            it 'sets the relative_position based on id after the last existing position' do
              subject

              expect(ordered_by_relative_position.map(&:epic_id)).to eq([epic3.id, epic1.id, epic4.id, epic2.id])

              expect(ordered_by_relative_position.map(&:relative_position))
                .to eq([10, 1000, 1000 + ideal_distance * 2, 1000 + ideal_distance * 3])
            end
          end

          context 'when there is no space for new positions' do
            let_it_be(:epic_position1) { create(:epic_board_position, epic: epic1, epic_board: board, relative_position: Boards::EpicBoardPosition::MAX_POSITION) }

            it 'raises an error' do
              expect { subject }.to raise_error(ActiveModel::RangeError)
            end
          end
        end

        context 'when all positions exist' do
          let_it_be(:epic_position1) { create(:epic_board_position, epic: epic1, epic_board: board, relative_position: 1000) }
          let_it_be(:epic_position2) { create(:epic_board_position, epic: epic2, epic_board: board, relative_position: 10) }
          let_it_be(:epic_position3) { create(:epic_board_position, epic: epic3, epic_board: board, relative_position: 10) }
          let_it_be(:epic_position4) { create(:epic_board_position, epic: epic4, epic_board: board, relative_position: 10) }

          it 'does not create new positions' do
            expect { subject }.not_to change { Boards::EpicBoardPosition.count }
          end
        end
      end

      context 'with additional params' do
        context 'for backlog list' do
          let(:params) { { board_id: board.id, list_id: list.id, from_id: epic2.id } }

          it 'creates the positions for all epics until the last param' do
            expect { subject }.to change { Boards::EpicBoardPosition.count }.by(3)
          end

          it 'sets the relative_position based on id' do
            subject

            expect(ordered_by_relative_position.map(&:epic_id)).to eq([epic4.id, epic3.id, epic2.id])
            expect(ordered_by_relative_position.map(&:relative_position))
              .to eq([ideal_distance * 2, ideal_distance * 3, ideal_distance * 4])
          end
        end

        context 'for labeled list' do
          let_it_be(:label) { create(:group_label, group: group, name: 'Development') }
          let_it_be(:labeled_list) { create(:epic_list, epic_board: board, label: label) }

          let(:params) { { board_id: board.id, list_id: labeled_list.id, from_id: epic2.id } }

          before do
            epic1.labels = [label]
            epic2.labels = [label]
            epic4.labels = [label]
          end

          it 'creates the positions for all epics until the last param' do
            expect { subject }.to change { Boards::EpicBoardPosition.count }.by(2)
          end

          it 'sets the relative_position based on id only for the epis with list label' do
            subject

            expect(ordered_by_relative_position.map(&:epic_id)).to eq([epic4.id, epic2.id])
            expect(ordered_by_relative_position.map(&:relative_position)).to eq([ideal_distance * 2, ideal_distance * 3])
          end
        end
      end
    end
  end
end
