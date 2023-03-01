# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Issues::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let(:project) { create(:project) }
    let(:board)   { create(:board, project: project) }
    let(:user)    { create(:user) }
    let(:label)   { create(:label, project: project, name: 'in-progress') }

    subject(:service) do
      described_class.new(board.resource_parent, project, user, board_id: board.id, list_id: list.id, title: 'New issue')
    end

    before do
      project.add_developer(user)
    end

    context 'saved board configuration' do
      let(:list) { create(:list, board: board, label: label, position: 0) }

      it 'adds the board assignee, weight, labels and milestone to the issue' do
        board_assignee = create(:user)
        project.add_developer(board_assignee)
        board_milestone = create(:milestone, project: project)
        board_label = create(:label, project: project)
        board.update!(assignee: board_assignee,
                      milestone: board_milestone,
                      label_ids: [board_label.id],
                      weight: 4)

        result = service.execute
        issue = result[:issue]

        expect(result).to be_success
        expect(issue.assignees).to eq([board_assignee])
        expect(issue.weight).to eq(board.weight)
        expect(issue.milestone).to eq(board_milestone)
        expect(issue.labels).to contain_exactly(label, board_label)
      end

      context 'when board is scoped by weight' do
        it 'creates issue weight 0 weight' do
          board.update!(weight: 0)

          result = service.execute
          issue = result[:issue]

          expect(result).to be_success
          expect(issue.weight).to be_zero
          expect(issue).to be_valid
        end

        it 'creates issue with nil weight' do
          board.update!(weight: nil)

          result = service.execute
          issue = result[:issue]

          expect(result).to be_success
          expect(issue.weight).to be_nil
          expect(issue).to be_valid
        end

        context 'when board weight is invalid' do
          it 'creates issue with nil weight' do
            board.update!(weight: -1)

            result = service.execute
            issue = result[:issue]

            expect(result).to be_success
            expect(issue.weight).to be_nil
            expect(issue).to be_valid
          end
        end
      end
    end

    context 'assignees list' do
      before do
        stub_licensed_features(board_assignee_lists: true)
      end

      let(:list) do
        create(:list, board: board, user: user, list_type: List.list_types[:assignee], position: 0)
      end

      it 'assigns the issue to the List assignee' do
        result = service.execute
        issue = result[:issue]

        expect(result).to be_success
        expect(issue.assignees).to eq([user])
      end
    end

    context 'milestone list' do
      before do
        stub_licensed_features(board_milestone_lists: true)
      end

      let(:milestone) { create(:milestone, project: project) }
      let(:list) do
        create(:list, board: board, milestone: milestone, list_type: List.list_types[:milestone], position: 0)
      end

      it 'assigns the issue to the list milestone' do
        result = service.execute
        issue = result[:issue]

        expect(result).to be_success
        expect(issue.milestone).to eq(milestone)
      end
    end
  end
end
