# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Epics::MoveService do
  describe '#execute' do
    let_it_be(:user) { create(:user) }
    let_it_be(:group) { create(:group) }
    let_it_be(:board) { create(:epic_board, group: group) }
    let_it_be(:other_board) { create(:epic_board, group: group) }

    let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
    let_it_be(:testing) { create(:group_label, group: group, name: 'Testing') }
    let_it_be(:no_board_label) { create(:group_label, group: group, name: 'Feature') }

    let_it_be(:backlog) { create(:epic_list, epic_board: board, list_type: :backlog, label: nil) }
    let_it_be(:development_list) { create(:epic_list, epic_board: board, label: development, position: 0) }
    let_it_be(:testing_list) { create(:epic_list, epic_board: board, label: testing, position: 1) }
    let_it_be(:closed) { create(:epic_list, epic_board: board, list_type: :closed, label: nil) }
    let_it_be(:other_board_list) { create(:epic_list, epic_board: other_board, list_type: :closed, label: nil) }

    let_it_be_with_reload(:epic) { create(:epic, group: group) }

    let(:params) { { board_id: board.id, from_list_id: from_list.id, to_list_id: to_list.id } }
    let(:from_list) { backlog }
    let(:to_list) { closed }

    before do
      stub_licensed_features(epics: true)
    end

    subject { described_class.new(group, user, params).execute(epic) }

    context 'when user does not have permissions to move an epic' do
      it 'does not close the epic' do
        expect { subject }.not_to change { epic.state }
      end
    end

    context 'when user has permissions to move an epic' do
      before do
        group.add_maintainer(user)
      end

      context 'when moving an epic between lists' do
        context 'when moving the epic from backlog' do
          context 'to a labeled list' do
            let(:to_list) { development_list }

            it 'keeps the epic opened and adds the labels' do
              expect { subject }.not_to change { epic.state }

              expect(epic.labels).to eq([development])
            end
          end

          context 'to the closed list' do
            it 'closes the epic' do
              expect { subject }.to change { epic.state }.from('opened').to('closed')
            end
          end

          context 'to the closed list in another board' do
            let(:to_list) { other_board_list }

            it 'does not close the epic' do
              expect { subject }.not_to change { epic.state }
            end
          end
        end

        context 'when moving the epic from a labeled list' do
          before do
            epic.labels = [development, no_board_label]
          end

          let(:from_list) { development_list }

          context 'to another labeled list' do
            let(:to_list) { testing_list }

            it 'changes the labels' do
              subject

              expect(epic.labels).to match_array([testing, no_board_label])
            end
          end

          context 'to the closed list' do
            let(:to_list) { closed }

            it 'closes the epic' do
              expect { subject }.to change { epic.state }.from('opened').to('closed')
            end

            it 'removes the board labels from the epic' do
              subject

              expect(epic.labels).to eq([no_board_label])
            end
          end
        end
      end

      context 'when repositioning an epic' do
        let_it_be(:epic1) { create(:epic, group: group) }
        let_it_be(:epic2) { create(:epic, group: group) }
        let_it_be(:epic3) { create(:epic, group: group) }

        def create_positions
          create(:epic_board_position, epic: epic3, epic_board: board, relative_position: 40)
          create(:epic_board_position, epic: epic, epic_board: board, relative_position: 50)
          create(:epic_board_position, epic: epic2, epic_board: board, relative_position: 60)
          create(:epic_board_position, epic: epic1, epic_board: board, relative_position: 80)
        end

        let(:params) do
          {
            board_id: board.id,
            to_list_id: backlog.id
          }
        end

        def epic_relative_position(epic)
          epic.epic_board_positions.find_by(epic_board_id: board.id)&.relative_position
        end

        context 'with invalid params' do
          context 'with board from another group' do
            let(:other_group) { create(:group) }
            let(:board) { create(:epic_board, group: other_group) }

            before do
              other_group.add_maintainer(user)
              params[:move_before_id] = epic2.id
            end

            it 'raises an error' do
              expect { subject }.to raise_error(ActiveRecord::RecordNotFound)
            end
          end
        end

        shared_examples 'correct positioning' do
          context 'when both move_before_id and move_after_id are present' do
            before do
              params[:move_before_id] = epic2.id
              params[:move_after_id] = epic1.id
            end

            it 'moves the epic' do
              subject

              expect(epic_relative_position(epic)).to be > epic_relative_position(epic2)
            end
          end

          context 'when only move_before_id is present' do
            before do
              params[:move_before_id] = epic1.id
            end

            it 'moves the epic' do
              subject

              expect(epic_relative_position(epic)).to be > epic_relative_position(epic1)
            end
          end

          context 'when only move_after_id is present' do
            before do
              params[:move_after_id] = epic3.id
            end

            it 'moves the epic' do
              subject

              expect(epic_relative_position(epic)).to be < epic_relative_position(epic3)
            end
          end

          context 'when only position_in_list is present' do
            before do
              params[:position_in_list] = position_in_list
            end

            context 'when moving to a specific position' do
              let(:position_in_list) { 4 }

              it 'moves the epic' do
                subject

                expect(epic_relative_position(epic)).to be > epic_relative_position(epic3)
                expect(epic_relative_position(epic)).to be > epic_relative_position(epic2)
                expect(epic_relative_position(epic)).to be > epic_relative_position(epic1)
              end
            end

            context 'when moving to the beginning' do
              let(:position_in_list) { 0 }

              it 'moves the epic' do
                subject

                expect(epic_relative_position(epic)).to be < epic_relative_position(epic3)
              end
            end

            context 'when moving to the bottom' do
              let(:position_in_list) { -1 }

              it 'moves the epic' do
                subject

                expect(epic_relative_position(epic)).to be > epic_relative_position(epic1)
              end
            end
          end
        end

        context 'in current list' do
          context 'when all epics have respective position records' do
            before do
              create_positions
            end

            it_behaves_like 'correct positioning'
          end

          context 'when epics do not have respective position records' do
            it_behaves_like 'correct positioning'
          end
        end

        context 'during a movement to another list' do
          before do
            epic.labels = [development]
          end

          context 'when all epics have respective position records' do
            before do
              create_positions
            end

            it_behaves_like 'correct positioning'
          end

          context 'when epics do not have respective position records' do
            it_behaves_like 'correct positioning'
          end
        end
      end
    end
  end
end
