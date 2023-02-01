# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Reposition and move epic between board lists', feature_category: :portfolio_management do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
  let(:epic) { create(:epic, group: group) }

  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:backlog) { create(:epic_list, epic_board: board, list_type: :backlog) }
  let_it_be(:labeled_list) { create(:epic_list, epic_board: board, label: development) }

  let(:mutation_class) { Mutations::Boards::EpicBoards::EpicMoveList }
  let(:mutation_name) { mutation_class.graphql_name }
  let(:mutation_result_identifier) { mutation_name.camelize(:lower) }

  let(:params) do
    {
      board_id: global_id_of(board),
      epic_id: global_id_of(epic)
    }
  end

  let(:move_params) do
    {
      from_list_id: global_id_of(backlog),
      to_list_id: global_id_of(labeled_list)
    }
  end

  subject { post_graphql_mutation(mutation(params), current_user: current_user) }

  context 'when epics are available' do
    before do
      stub_licensed_features(epics: true)
    end

    context 'when user does not have permissions to admin the board' do
      it 'raises resource not available error' do
        subject

        message = Gitlab::Graphql::Authorize::AuthorizeResource::RESOURCE_ACCESS_ERROR
        expect(graphql_errors).to include(a_hash_including('message' => message))
      end
    end

    context 'when user has permissions to admin the board' do
      before do
        group.add_developer(current_user)
      end

      context 'when required move params are missing' do
        let(:move_params) { { to_list_id: global_id_of(backlog) } }

        it 'raises an error' do
          subject

          message = 'At least one of the following parameters is required: fromListId, moveAfterId, moveBeforeId, positionInList.'
          expect(graphql_errors).to include(a_hash_including('message' => message))
        end
      end

      context 'when positionInList param is invalid' do
        let(:base_params) { { to_list_id: global_id_of(backlog), position_in_list: 1 } }

        context 'when move_before_id is also given' do
          let(:move_params) { base_params.merge({ move_before_id: global_id_of(epic) }) }

          it 'raises an error' do
            subject

            message = 'positionInList is mutually exclusive with any of moveBeforeId or moveAfterId'
            expect(graphql_errors).to include(a_hash_including('message' => message))
          end
        end

        context 'when move_after_id is also given' do
          let(:move_params) { base_params.merge({ move_after_id: global_id_of(epic) }) }

          it 'raises an error' do
            subject

            message = 'positionInList is mutually exclusive with any of moveBeforeId or moveAfterId'
            expect(graphql_errors).to include(a_hash_including('message' => message))
          end
        end

        context 'when position_in_list is invalid' do
          let(:move_params) { base_params.merge({ position_in_list: -5 }) }

          it 'raises an error' do
            subject

            message = "positionInList must be >= 0 or #{Boards::Epics::MoveService::LIST_END_POSITION}"
            expect(graphql_errors).to include(a_hash_including('message' => message))
          end
        end
      end

      context 'moving an epic to another list' do
        # rubocop: disable CodeReuse/ActiveRecord
        it 'moves the epic to another list' do
          expect { subject }.to change { epic.reload.labels }.from([]).to([development])
        end
        # rubocop: enable CodeReuse/ActiveRecord
      end

      context 'repositioning an epic' do
        let!(:epic1) { create(:epic, group: group) }
        let!(:epic_board_position) { create(:epic_board_position, epic_board: board, epic: epic1) }
        let!(:epic2) { create(:epic, group: group) }
        let!(:epic3) { create(:epic, group: group) }

        def position(epic)
          epic.epic_board_positions.first.relative_position
        end

        context 'when both move_before_id and move_after_id params are present' do
          let(:move_params) do
            {
              move_before_id: global_id_of(epic3),
              move_after_id: global_id_of(epic2),
              to_list_id: global_id_of(backlog)
            }
          end

          it 'repositions the epic' do
            subject

            expect(position(epic)).to be > position(epic3)
          end
        end

        context 'when only move_before_id param is present' do
          let(:move_params) do
            {
              to_list_id: global_id_of(backlog),
              move_before_id: global_id_of(epic3)
            }
          end

          it 'repositions the epic' do
            subject

            expect(position(epic)).to be > position(epic3)
          end
        end

        context 'when only move_after_id param is present' do
          let(:move_params) do
            {
              to_list_id: global_id_of(backlog),
              move_after_id: global_id_of(epic3)
            }
          end

          it 'repositions the epic' do
            subject

            expect(position(epic)).to be < position(epic3)
          end
        end

        context 'when position_in_list param is present' do
          before do
            create(:epic_board_position, epic_board: board, epic: epic2, relative_position: 1000)
            create(:epic_board_position, epic_board: board, epic: epic3, relative_position: 2000)
          end

          let(:move_params) do
            {
              position_in_list: position_in_list,
              to_list_id: global_id_of(backlog)
            }
          end

          context 'when moving an epic to the beginning of the list' do
            let(:position_in_list) { 0 }

            it 'repositions the epic' do
              subject

              expect(position(epic)).to be < position(epic2)
              expect(position(epic)).to be < position(epic3)
            end
          end

          context 'when moving an epic to the bottom of the list' do
            let(:position_in_list) { -1 }

            it 'repositions the epic' do
              subject

              expect(position(epic)).to be > position(epic2)
              expect(position(epic)).to be > position(epic3)
            end
          end
        end
      end
    end
  end

  def mutation(additional_params = {})
    graphql_mutation(mutation_name, move_params.merge(additional_params),
      <<-QL.strip_heredoc
        clientMutationId
        epic {
          iid,
          relativePosition
          labels {
            nodes {
              title
            }
          }
        }
        errors
    QL
    )
  end
end
