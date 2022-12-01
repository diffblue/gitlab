# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Lists::Create do
  include GraphqlHelpers

  let_it_be(:group)     { create(:group, :private) }
  let_it_be(:board)     { create(:board, group: group) }
  let_it_be(:milestone) { create(:milestone, group: group) }
  let_it_be(:user)      { create(:user) }
  let_it_be(:guest)     { create(:user) }

  let(:current_user) { user }
  let(:mutation) { described_class.new(object: nil, context: { current_user: current_user }, field: nil) }
  let(:list_create_params) { {} }

  before_all do
    group.add_reporter(user)
    group.add_guest(guest)
  end

  before do
    stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true, board_iteration_lists: true)
  end

  subject { mutation.resolve(board_id: board.to_global_id.to_s, **list_create_params) }

  describe '#ready?' do
    it 'raises an error if required arguments are missing' do
      expect { mutation.ready?(board_id: 'some id') }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError,
                        'one and only one of backlog or labelId or milestoneId or iterationId or assigneeId is required')
    end

    it 'raises an error if too many required arguments are specified' do
      expect { mutation.ready?(board_id: 'some id', milestone_id: 'some milestone', assignee_id: 'some label') }
        .to raise_error(Gitlab::Graphql::Errors::ArgumentError,
                        'one and only one of backlog or labelId or milestoneId or iterationId or assigneeId is required')
    end
  end

  describe '#resolve' do
    context 'with proper permissions' do
      describe 'milestone list' do
        let(:list_create_params) { { milestone_id: milestone.to_global_id.to_s } }

        context 'when feature unavailable' do
          it 'returns an error' do
            stub_licensed_features(board_milestone_lists: false)

            expect(subject[:errors]).to include 'Milestone lists not available with your current license'
          end
        end

        it 'creates a new issue board list for milestones' do
          expect { subject }.to change { board.lists.count }.from(1).to(2)

          new_list = subject[:list]

          expect(new_list.title).to eq milestone.title
          expect(new_list.milestone_id).to eq milestone.id
          expect(new_list.position).to eq 0
        end

        context 'when milestone not found' do
          let(:list_create_params) { { milestone_id: "gid://gitlab/Milestone/#{non_existing_record_id}" } }

          it 'returns an error' do
            expect(subject[:errors]).to include 'Milestone not found'
          end
        end
      end

      describe 'assignee list' do
        let(:list_create_params) { { assignee_id: guest.to_global_id.to_s } }

        context 'when feature unavailable' do
          it 'returns an error' do
            stub_licensed_features(board_assignee_lists: false)

            expect(subject[:errors]).to include 'Assignee lists not available with your current license'
          end
        end

        it 'creates a new issue board list for assignees' do
          expect { subject }.to change { board.lists.count }.from(1).to(2)

          new_list = subject[:list]

          expect(new_list.title).to eq "@#{guest.username}"
          expect(new_list.user_id).to eq guest.id
          expect(new_list.position).to eq 0
        end

        context 'when user not found' do
          let(:list_create_params) { { assignee_id: "gid://gitlab/User/#{non_existing_record_id}" } }

          it 'returns an error' do
            expect(subject[:errors]).to include 'Assignee not found'
          end
        end
      end

      describe 'iteration list' do
        let(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }
        let(:list_create_params) { { iteration_id: iteration.to_global_id.to_s } }

        context 'when feature unavailable' do
          it 'returns an error' do
            stub_licensed_features(board_iteration_lists: false)

            expect(subject[:errors]).to include 'Iteration lists not available with your current license'
          end
        end

        it 'creates a new issue board list for the iteration' do
          expect { subject }.to change { board.lists.count }.from(1).to(2)

          new_list = subject[:list]

          expect(new_list.title).to eq iteration.display_text
          expect(new_list.iteration_id).to eq iteration.id
          expect(new_list.position).to eq 0
        end

        context 'when iteration not found' do
          let(:list_create_params) { { iteration_id: "gid://gitlab/Iteration/#{non_existing_record_id}" } }

          it 'returns an error' do
            expect(subject[:errors]).to include 'Iteration not found'
          end
        end
      end
    end

    context 'without proper permissions' do
      let(:current_user) { guest }

      it 'raises an error' do
        expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end
  end
end
