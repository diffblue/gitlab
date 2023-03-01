# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Boards::Issues::MoveService, services: true, feature_category: :team_planning do
  shared_examples 'moving an issue to/from milestone lists' do
    context 'from backlog to milestone list' do
      let!(:issue) { create(:labeled_issue, project: project) }

      it 'assigns the milestone' do
        params = { board_id: board1.id, from_list_id: backlog.id, to_list_id: milestone_list1.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(nil)
          .to(milestone_list1.milestone)
      end
    end

    context 'from milestone to backlog list' do
      let!(:issue) { create(:labeled_issue, project: project, milestone: milestone_list1.milestone) }

      it 'removes the milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: backlog.id }
        expect { described_class.new(parent, user, params).execute(issue) }.to change { issue.reload.milestone }
          .from(milestone_list1.milestone)
          .to(nil)
      end
    end

    context 'from label to milestone list' do
      let(:issue) { create(:labeled_issue, project: project, labels: [bug, development]) }

      it 'assigns the milestone and keeps labels' do
        params = { board_id: board1.id, from_list_id: label_list1.id, to_list_id: milestone_list1.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(nil)
          .to(milestone_list1.milestone)

        expect(issue.labels).to contain_exactly(bug, development)
      end
    end

    context 'from milestone to label list' do
      let!(:issue) do
        create(:labeled_issue, project: project,
                               milestone: milestone_list1.milestone,
                               labels: [bug, development])
      end

      it 'adds labels and keeps milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: label_list2.id }

        described_class.new(parent, user, params).execute(issue)
        issue.reload

        expect(issue.labels).to contain_exactly(bug, development, testing)
      end
    end

    context 'from assignee to milestone list' do
      let!(:issue) { create(:labeled_issue, project: project, assignees: [user], milestone: nil) }

      it 'assigns the milestone and keeps assignees' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: milestone_list1.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(nil)
          .to(milestone_list1.milestone)

        expect(issue.assignees).to eq([user])
      end
    end

    context 'from milestone to assignee list' do
      let!(:issue) { create(:labeled_issue, project: project, milestone: milestone_list1.milestone) }

      it 'assigns the user and keeps milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: user_list1.id }

        described_class.new(parent, user, params).execute(issue)
        issue.reload

        expect(issue.milestone).to eq(milestone_list1.milestone)
        expect(issue.assignees).to contain_exactly(user_list1.user)
      end
    end

    context 'between milestone lists' do
      let!(:issue) { create(:labeled_issue, project: project, milestone: milestone_list1.milestone) }

      it 'replaces previous list milestone to targeting list milestone' do
        params = { board_id: board1.id, from_list_id: milestone_list1.id, to_list_id: milestone_list2.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.milestone }
          .from(milestone_list1.milestone)
          .to(milestone_list2.milestone)
      end
    end
  end

  shared_examples 'moving an issue to/from iteration lists' do
    context 'from backlog to iteration list' do
      let!(:issue) { create(:issue, project: project) }
      let(:params) { { board_id: board1.id, from_list_id: backlog.id, to_list_id: iteration_list1.id } }

      it 'assigns the iteration' do
        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.iteration }
          .from(nil)
          .to(iteration_list1.iteration)
      end
    end

    context 'from iteration to backlog list' do
      let!(:issue) { create(:issue, project: project, iteration: iteration_list1.iteration) }

      it 'removes the iteration' do
        params = { board_id: board1.id, from_list_id: iteration_list1.id, to_list_id: backlog.id }
        expect { described_class.new(parent, user, params).execute(issue) }.to change { issue.reload.iteration }
          .from(iteration_list1.iteration)
          .to(nil)
      end
    end

    context 'from label to iteration list' do
      let(:issue) { create(:labeled_issue, project: project, labels: [bug, development]) }

      it 'assigns the iteration and keeps labels' do
        params = { board_id: board1.id, from_list_id: label_list1.id, to_list_id: iteration_list1.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.iteration }
          .from(nil)
          .to(iteration_list1.iteration)

        expect(issue.labels).to contain_exactly(bug, development)
      end
    end

    context 'from iteration to label list' do
      let!(:issue) do
        create(:labeled_issue, project: project,
                               iteration: iteration_list1.iteration,
                               labels: [bug, development])
      end

      it 'adds labels and keeps iteration' do
        params = { board_id: board1.id, from_list_id: iteration_list1.id, to_list_id: label_list2.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .not_to change { issue.reload.iteration }

        expect(issue.labels).to contain_exactly(bug, development, testing)
      end
    end

    context 'between iteration lists' do
      let!(:issue) { create(:issue, project: project, iteration: iteration_list1.iteration) }

      it 'replaces previous list iteration to targeting list iteration' do
        params = { board_id: board1.id, from_list_id: iteration_list1.id, to_list_id: iteration_list2.id }

        expect { described_class.new(parent, user, params).execute(issue) }
          .to change { issue.reload.iteration }
          .from(iteration_list1.iteration)
          .to(iteration_list2.iteration)
      end
    end
  end

  shared_examples 'moving an issue to/from assignee lists' do
    let(:issue)  { create(:labeled_issue, project: project, labels: [bug, development], milestone: milestone1) }
    let(:params) { { board_id: board1.id, from_list_id: label_list1.id, to_list_id: label_list2.id } }

    context 'from assignee to label list' do
      it 'does not unassign and adds label' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: label_list2.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development, testing)
        expect(issue.assignees).to contain_exactly(user_list1.user)
        expect(issue.milestone).to eq(milestone1)
      end
    end

    context 'from assignee to backlog' do
      it 'removes assignment and keeps milestone' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: backlog.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.assignees).to eq([])
        expect(issue).not_to be_closed
        expect(issue.milestone).to eq(milestone1)
      end
    end

    context 'from assignee to closed list' do
      it 'keeps assignment and closes the issue' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: closed.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.assignees).to contain_exactly(user_list1.user)
        expect(issue).to be_closed
        expect(issue.milestone).to eq(milestone1)
      end
    end

    context 'from label list to assignee' do
      it 'assigns and does not remove label' do
        params = { board_id: board1.id, from_list_id: label_list1.id, to_list_id: user_list1.id }

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development)
        expect(issue.assignees).to contain_exactly(user_list1.user)
        expect(issue.milestone).to eq(milestone1)
      end
    end

    context 'between two assignee lists' do
      it 'unassigns removal and assigns addition' do
        params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: user_list2.id }
        issue.assignees.push(user_list1.user)
        expect(issue.assignees).to contain_exactly(user_list1.user)

        described_class.new(parent, user, params).execute(issue)

        issue.reload
        expect(issue.labels).to contain_exactly(bug, development)
        expect(issue.assignees).to contain_exactly(user)
        expect(issue.milestone).to eq(milestone1)
      end

      context 'when cannot assign to target list user' do
        it 'returns error' do
          random_list = create(:user_list, board: board1, position: 2)
          params = { board_id: board1.id, from_list_id: user_list1.id, to_list_id: random_list.id }

          result = described_class.new(parent, user, params).execute(issue)

          expect(result[:status]).to eq(:error)
        end
      end
    end
  end

  describe '#execute' do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, namespace: group) }
    let_it_be(:cadence) { create(:iterations_cadence, group: group) }
    let_it_be(:iteration1) { create(:iteration, iterations_cadence: cadence) }
    let_it_be(:iteration2) { create(:iteration, iterations_cadence: cadence) }

    let(:user) { create(:user) }

    let!(:board1) { create(:board, **parent_attr) }
    let(:board2) { create(:board, **parent_attr) }

    let(:label_list1) { create(:list, board: board1, label: development, position: 0) }
    let(:label_list2) { create(:list, board: board1, label: testing, position: 1) }
    let(:user_list1) { create(:user_list, board: board1, position: 2) }
    let(:user_list2) { create(:user_list, board: board1, user: user, position: 3) }
    let(:milestone_list1) { create(:milestone_list, board: board1, milestone: milestone1, position: 4) }
    let(:milestone_list2) { create(:milestone_list, board: board1, milestone: milestone2, position: 5) }
    let(:iteration_list1) { create(:iteration_list, board: board1, iteration: iteration1, position: 6) }
    let(:iteration_list2) { create(:iteration_list, board: board1, iteration: iteration2, position: 7) }
    let(:closed) { create(:closed_list, board: board1) }
    let(:backlog) { create(:backlog_list, board: board1) }

    context 'when parent is a project' do
      let_it_be(:milestone1) { create(:milestone, project: project) }
      let_it_be(:milestone2) { create(:milestone, project: project) }
      let_it_be(:bug) { create(:label, project: project, name: 'Bug') }
      let_it_be(:development) { create(:label, project: project, name: 'Development') }
      let_it_be(:testing) { create(:label, project: project, name: 'Testing') }
      let_it_be(:regression) { create(:label, project: project, name: 'Regression') }

      let(:parent_attr) { { project: project } }
      let(:parent) { project }

      before do
        stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true, board_iteration_lists: true)
        parent.add_developer(user)
        parent.add_developer(user_list1.user)
      end

      it_behaves_like 'moving an issue to/from assignee lists'
      it_behaves_like 'moving an issue to/from milestone lists'
      it_behaves_like 'moving an issue to/from iteration lists'
    end

    context 'when parent is a group' do
      let_it_be(:milestone1) { create(:milestone, group: group) }
      let_it_be(:milestone2) { create(:milestone, group: group) }
      let_it_be(:bug) { create(:group_label, group: group, name: 'Bug') }
      let_it_be(:development) { create(:group_label, group: group, name: 'Development') }
      let_it_be(:testing) { create(:group_label, group: group, name: 'Testing') }
      let_it_be(:regression) { create(:group_label, group: group, name: 'Regression') }

      let(:parent_attr) { { group: group } }
      let(:parent) { group }

      before do
        stub_licensed_features(board_assignee_lists: true, board_milestone_lists: true)
        parent.add_developer(user)
        parent.add_developer(user_list1.user)
      end

      it_behaves_like 'moving an issue to/from assignee lists'
      it_behaves_like 'moving an issue to/from milestone lists'
      it_behaves_like 'moving an issue to/from iteration lists'

      context 'when moving to same list' do
        let(:subgroup) { create(:group, parent: group) }
        let(:subgroup_project) { create(:project, namespace: subgroup) }

        it 'sorts issues included in subgroups' do
          labels = [bug, development]
          issue  = create(:labeled_issue, project: subgroup_project, labels: labels)
          issue0 = create(:labeled_issue, project: subgroup_project, labels: labels)
          issue1 = create(:labeled_issue, project: project, labels: labels)
          issue2 = create(:labeled_issue, project: project, labels: labels)
          params = { board_id: board1.id, from_list_id: label_list1.id, to_list_id: label_list1.id }

          reorder_issues(params, issues: [issue, issue0, issue1, issue2])
          described_class.new(parent, user, params).execute(issue)

          expect(issue.relative_position).to be_between(issue0.relative_position, issue1.relative_position)
        end
      end

      def reorder_issues(params, issues: [])
        issues.each do |issue|
          issue.move_to_end && issue.save!
        end

        params.merge!(move_after_id: issues[1].id, move_before_id: issues[2].id)
      end
    end
  end
end
