# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Lists::ListService, feature_category: :team_planning do
  describe '#execute' do
    before do
      stub_licensed_features(board_assignee_lists: false, board_milestone_lists: false, board_iteration_lists: false)
    end

    def execute_service
      service.execute(Board.find(board.id))
    end

    shared_examples 'list service for board with assignee lists' do
      let!(:assignee_list) { build(:user_list, board: board).tap { |l| l.save!(validate: false) } }
      let!(:backlog_list) { create(:backlog_list, board: board) }
      let!(:list) { create(:list, board: board, label: label) }

      context 'when the feature is enabled' do
        before do
          stub_licensed_features(board_assignee_lists: true)
        end

        it 'returns all lists' do
          expect(execute_service).to match_array [backlog_list, list, assignee_list, board.lists.closed.first]
        end
      end

      context 'when the feature is disabled' do
        it 'filters out assignee lists that might have been created while subscribed' do
          expect(execute_service).to match_array [backlog_list, list, board.lists.closed.first]
        end
      end
    end

    shared_examples 'list service for board with milestone lists' do
      let!(:milestone_list) { build(:milestone_list, board: board).tap { |l| l.save!(validate: false) } }
      let!(:backlog_list) { create(:backlog_list, board: board) }
      let!(:list) { create(:list, board: board, label: label) }

      context 'when the feature is enabled' do
        before do
          stub_licensed_features(board_milestone_lists: true)
        end

        it 'returns all lists' do
          expect(execute_service)
            .to match_array([backlog_list, list, milestone_list, board.lists.closed.first])
        end
      end

      context 'when the feature is disabled' do
        it 'filters out assignee lists that might have been created while subscribed' do
          expect(execute_service).to match_array [backlog_list, list, board.lists.closed.first]
        end
      end
    end

    shared_examples 'list service for board with iteration lists' do
      let!(:iteration_list) { build(:iteration_list, board: board).tap { |l| l.save!(validate: false) } }
      let!(:backlog_list) { create(:backlog_list, board: board) }
      let!(:list) { create(:list, board: board, label: label) }

      context 'when the feature is enabled' do
        before do
          stub_licensed_features(board_iteration_lists: true)
        end

        it 'returns all lists' do
          expect(execute_service)
            .to match_array([backlog_list, list, iteration_list, board.lists.closed.first])
        end
      end

      context 'when feature is disabled' do
        it 'filters out iteration lists that might have been created while subscribed' do
          expect(execute_service).to match_array [backlog_list, list, board.lists.closed.first]
        end
      end
    end

    context 'when board parent is a project' do
      let(:user) { create(:user) }
      let(:project) { create(:project) }
      let(:board) { create(:board, project: project) }
      let(:label) { create(:label, project: project) }
      let(:service) { described_class.new(project, user) }

      it_behaves_like 'list service for board with assignee lists'
      it_behaves_like 'list service for board with milestone lists'
      it_behaves_like 'list service for board with iteration lists'
    end

    context 'when board parent is a group' do
      let(:user) { create(:user) }
      let(:group) { create(:group) }
      let(:board) { create(:board, group: group) }
      let(:label) { create(:group_label, group: group) }
      let(:service) { described_class.new(group, user) }

      it_behaves_like 'list service for board with assignee lists'
      it_behaves_like 'list service for board with milestone lists'
      it_behaves_like 'list service for board with iteration lists'
    end
  end
end
