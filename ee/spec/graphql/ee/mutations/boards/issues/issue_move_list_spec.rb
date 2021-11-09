# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Boards::Issues::IssueMoveList do
  let_it_be(:group) { create(:group, :public) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:board) { create(:board, group: group) }
  let_it_be(:epic) { create(:epic, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:issue1) { create(:labeled_issue, project: project, relative_position: 3) }
  let_it_be(:existing_issue1) { create(:labeled_issue, project: project, relative_position: 10) }
  let_it_be(:existing_issue2) { create(:labeled_issue, project: project, relative_position: 50) }

  let(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }
  let(:params) { { board: board, project_path: project.full_path, iid: issue1.iid } }
  let(:move_params) do
    {
      epic_id: epic.to_global_id,
      move_before_id: existing_issue2.id,
      move_after_id: existing_issue1.id
    }
  end

  before do
    stub_licensed_features(epics: true)
    project.add_reporter(user)
  end

  subject do
    mutation.resolve(**params.merge(move_params))
  end

  describe '#resolve' do
    context 'when user has access to the epic' do
      before do
        group.add_guest(user)
      end

      it 'moves and repositions issue' do
        subject

        expect(issue1.reload.epic).to eq(epic)
        expect(issue1.relative_position).to be < existing_issue2.relative_position
        expect(issue1.relative_position).to be > existing_issue1.relative_position
      end
    end

    context 'when user does not have access to the epic' do
      let(:epic) { create(:epic, :confidential, group: group) }

      it 'does not update issue' do
        subject

        expect(issue1.reload.epic).to be_nil
        expect(issue1.relative_position).to eq(3)
      end
    end

    context 'when user cannot be assigned to issue' do
      before do
        stub_licensed_features(board_assignee_lists: true)
      end

      it 'returns error on result' do
        params[:to_list_id] = create(:user_list, board: board, position: 2).id

        result = mutation.resolve(**params)

        expect(result[:errors]).to eq(['Not authorized to assign issue to list user'])
      end
    end
  end
end
