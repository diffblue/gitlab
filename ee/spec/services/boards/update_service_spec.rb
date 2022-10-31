# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::UpdateService, services: true do
  describe '#execute' do
    let_it_be(:parent_group) { create(:group) }
    let_it_be_with_refind(:group) { create(:group, parent: parent_group) }
    let_it_be_with_refind(:project) { create(:project, group: group) }
    let_it_be_with_reload(:board) { create(:board, group: group, name: 'Backend') }

    let_it_be(:assignee) { create(:user) }
    let_it_be(:milestone) { create(:milestone, group: group) }
    let_it_be(:iteration) { create(:iteration, iterations_cadence: create(:iterations_cadence, group: group)) }
    let_it_be(:parent_label) { create(:group_label, group: parent_group) }
    let_it_be(:other_label) { create(:group_label) }
    let_it_be(:label) { create(:group_label, group: group) }
    let_it_be(:user) { create(:user) }

    let(:all_params) do
      { milestone_id: milestone.id, iteration_id: iteration.id,
        assignee_id: assignee.id,
        label_ids: [label.id, other_label.id, parent_label.id],
        weight: 1, hide_backlog_list: true, hide_closed_list: true }
    end

    let(:updated_scoped_params) do
      { milestone: milestone, assignee: assignee, labels: [label, parent_label],
        weight: 1, hide_backlog_list: true, hide_closed_list: true }
    end

    let(:updated_without_scoped_params) do
      { milestone: nil, assignee: nil, labels: [], weight: nil,
        hide_backlog_list: true, hide_closed_list: true }
    end

    before do
      project.add_reporter(user)
    end

    context 'with group board' do
      let!(:board) { create(:board, group: group, name: 'Backend') }

      it_behaves_like 'board update service'
    end

    context 'with project board' do
      let!(:board) { create(:board, project: project, name: 'Backend') }

      it_behaves_like 'board update service'
    end

    context 'when setting a timebox' do
      let_it_be(:user) { create(:user) }

      before do
        parent.add_reporter(user)
      end

      subject do
        described_class.new(parent, user, args).execute(board)
        board.reload
      end

      it_behaves_like 'setting a milestone scope' do
        let(:args) { { milestone_id: milestone.id } }
      end

      it_behaves_like 'setting an iteration scope' do
        let(:args) { { iteration_id: iteration.id } }
      end
    end
  end
end
