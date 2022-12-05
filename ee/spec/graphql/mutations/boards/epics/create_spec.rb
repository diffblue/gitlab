# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Epics::Create do
  include GraphqlHelpers

  let_it_be(:user) { create(:user) }
  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:default_params) { { group_path: group.path, board_id: global_id_of(board), list_id: global_id_of(list), title: title } }
  let(:epic_create_params) { default_params }
  let_it_be(:group) { create(:group, :private) }
  let_it_be(:board) { create(:epic_board, group: group) }
  let_it_be(:label) do
    create(:group_label, title: 'Doing', color: '#FFAABB', group: group)
  end

  let_it_be(:list) { create(:epic_list, epic_board: board, label: label) }

  let(:title) { "The Illiad" }

  before do
    stub_licensed_features(epics: true)
  end

  subject { mutation.resolve(**epic_create_params) }

  context 'field tests' do
    subject { described_class }

    it { is_expected.to have_graphql_arguments(:boardId, :listId, :title, :groupPath) }
    it { is_expected.to have_graphql_fields(:epic).at_least }
  end

  shared_examples 'epic creation error' do
    it 'raises error' do
      expect { subject }
          .to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end
  end

  describe '#resolve' do
    context 'with proper permissions' do
      before_all do
        group.add_maintainer(user)
      end

      describe 'create epic via label list' do
        it 'creates a new epic' do
          expect { subject }.to change { Epic.count }.by(1)
        end

        it 'creates and returns a new epic with that label', :aggregate_failures do
          new_epic = subject[:epic]

          expect(new_epic.title).to eq title
          expect(new_epic.labels).to eq [label]
        end

        context 'when group not found' do
          let(:epic_create_params) { default_params.merge({ group_path: "nonsense" }) }

          it_behaves_like 'epic creation error'
        end

        context 'when board not found' do
          let(:epic_create_params) { default_params.merge({ board_id: "gid://gitlab/Boards::EpicBoard/#{non_existing_record_id}" }) }

          it 'returns an error' do
            expect(subject[:errors]).to include "Board not found"
          end
        end

        context 'when list not found' do
          let(:epic_create_params) { default_params.merge({ list_id: "gid://gitlab/Boards::EpicList/#{non_existing_record_id}" }) }

          it 'returns an error' do
            expect(subject[:errors]).to include "List not found"
          end
        end

        context 'when list is not under that board' do
          let_it_be(:other_board_list) { create(:epic_list) }

          let(:epic_create_params) { default_params.merge({ list_id: "gid://gitlab/Boards::EpicList/#{other_board_list.id}" }) }

          it 'returns an error' do
            expect(subject[:errors]).to include "List not found"
          end
        end

        context 'when title empty' do
          let(:epic_create_params) { default_params.merge({ title: "" }) }

          it 'returns an error' do
            expect(subject[:errors]).to include "Title can't be blank"
          end
        end

        context 'when title nil' do
          let(:epic_create_params) { default_params.merge({ title: nil }) }

          it 'returns an error' do
            expect(subject[:errors]).to include "Title can't be blank"
          end
        end
      end

      context 'with epics not available' do
        before do
          stub_licensed_features(epics: false)
        end

        it_behaves_like 'epic creation error'
      end
    end

    context 'without proper permissions' do
      before_all do
        group.add_guest(user)
      end

      it_behaves_like 'epic creation error'
    end
  end
end
