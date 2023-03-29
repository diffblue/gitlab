# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Notes::QuickActionsService do
  let_it_be(:group) { create(:group) }
  let_it_be(:private_group) { create(:group, :private) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user, reload: true) { create(:user) }
  let_it_be(:assignee) { create(:user) }
  let_it_be(:reviewer) { create(:user) }
  let_it_be(:issue, reload: true) { create(:issue, project: project) }
  let_it_be(:epic, reload: true) { create(:epic, group: group) }
  let_it_be(:private_epic) { create(:epic, group: private_group) }

  let(:service) { described_class.new(project, user) }

  def execute(note, include_message: false)
    content, update_params, message, _ = service.execute(note)
    service.apply_updates(update_params, note)

    if include_message
      [content, message]
    else
      content
    end
  end

  describe '/epic' do
    let(:note_text) { "/epic #{epic.to_reference(project)}" }
    let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

    before do
      group.add_guest(user)
    end

    context 'when epics are not enabled' do
      it 'does not assign the epic' do
        content, message = execute(note, include_message: true)

        expect(content).to be_empty
        expect(message).to eq('Could not apply epic command.')
        expect(issue.epic).to be_nil
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user have no access to the issue' do
        before do
          allow(user).to receive(:can?).and_call_original
          allow(user).to receive(:can?).with(:admin_issue_relation, issue).and_return(false)
        end

        it 'does not assign the epic' do
          content, message  = execute(note, include_message: true)

          expect(content).to be_empty
          expect(message).to eq('Could not apply epic command.')
          expect(issue.epic).to be_nil
        end
      end

      context 'when user have no access to the epic' do
        let(:note_text) { "/epic #{private_epic.to_reference(full: true)}" }

        it 'does not assign the epic' do
          content, message  = execute(note, include_message: true)

          expect(content).to be_empty
          expect(message).to eq("This epic does not exist or you don't have sufficient permission.")
          expect(issue.epic).to be_nil
        end
      end

      context 'on an issue' do
        it 'assigns the issue to the epic' do
          expect { execute(note) }.to change { issue.reload.epic }.from(nil).to(epic)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end

        it 'creates a system note', :sidekiq_inline do
          expect { execute(note) }.to change { Note.system.count }.from(0).to(2)
        end
      end

      context 'on an incident' do
        before do
          issue.update!(issue_type: :incident, work_item_type: WorkItems::Type.default_by_type(:incident))
        end

        it 'leaves the note empty' do
          expect(execute(note)).to be_empty
        end

        it 'does not assigns the issue to the epic' do
          expect { execute(note) }.not_to change { issue.reload.epic }
        end
      end

      context 'on a merge request' do
        let(:note_mr) { create(:note_on_merge_request, project: project, note: note_text) }

        it 'leaves the note empty' do
          expect(execute(note_mr)).to be_empty
        end
      end
    end
  end

  describe '/remove_epic' do
    let(:note_text) { "/remove_epic" }
    let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

    before do
      issue.update!(epic: epic)
      group.add_guest(user)
    end

    context 'when epics are not enabled' do
      it 'does not remove the epic' do
        content, message  = execute(note, include_message: true)

        expect(content).to be_empty
        expect(message).to eq('Could not apply remove_epic command.')
        expect(issue.epic).to eq(epic)
      end
    end

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when user have no access to the issue' do
        before do
          allow(user).to receive(:can?).and_call_original
          allow(user).to receive(:can?).with(:admin_issue_relation, issue).and_return(false)
        end

        it 'does not remove the epic' do
          result = execute(note, include_message: true)

          expect(result[0]).to be_empty
          expect(result[1]).to eq('Could not apply remove_epic command.')
          expect(issue.epic).to eq(epic)
        end
      end

      context 'when user have no access to the epic' do
        let(:note_text) { "/epic #{private_epic.to_reference(full: true)}" }

        before do
          issue.update!(epic: private_epic)
        end

        it 'does not remove the epic' do
          result = execute(note, include_message: true)

          expect(result[0]).to be_empty
          expect(result[1]).to eq("This epic does not exist or you don't have sufficient permission.")
          expect(issue.epic).to eq(private_epic)
        end
      end

      context 'on an issue' do
        it 'removes the epic' do
          expect { execute(note) }.to change { issue.reload.epic }.from(epic).to(nil)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end

        it 'creates a system note' do
          expect { execute(note) }.to change { Note.system.count }.from(0).to(2)
        end
      end

      context 'on an incident' do
        before do
          issue.assign_attributes(issue_type: :incident, work_item_type: WorkItems::Type.default_by_type(:incident))
          issue.save!(validate: false)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to be_empty
        end
      end

      context 'on a test case' do
        before do
          issue.assign_attributes(issue_type: :test_case, work_item_type: WorkItems::Type.default_by_type(:test_case))
          issue.save!(validate: false)
        end

        it 'leaves the note empty' do
          expect(execute(note)).to be_empty
        end
      end

      context 'on a merge request' do
        let(:note_mr) { create(:note_on_merge_request, project: project, note: note_text) }

        it 'leaves the note empty' do
          expect(execute(note_mr)).to be_empty
        end
      end
    end
  end

  describe 'Epics' do
    describe '/close' do
      let(:note_text) { "/close" }
      let(:note) { create(:note, noteable: epic, note: note_text) }

      before do
        group.add_developer(user)
      end

      context 'when epics are not enabled' do
        it 'does not close the epic' do
          expect { execute(note) }.not_to change { epic.state }
        end
      end

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'closes the epic' do
          expect { execute(note) }.to change { epic.reload.state }.from('opened').to('closed')
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end
      end
    end

    describe '/reopen' do
      let(:note_text) { "/reopen" }
      let(:note) { create(:note, noteable: epic, note: note_text) }

      before do
        group.add_developer(user)
        epic.update!(state: 'closed')
      end

      context 'when epics are not enabled' do
        it 'does not reopen the epic' do
          expect { execute(note) }.not_to change { epic.state }
        end
      end

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'reopens the epic' do
          expect { execute(note) }.to change { epic.reload.state }.from('closed').to('opened')
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end
      end
    end

    describe '/label' do
      let(:project) { nil }
      let!(:bug) { create(:group_label, title: 'bug', group: group) }
      let!(:project_label) { create(:label, title: 'project_label', project: create(:project, group: group)) }
      let(:note_text) { "/label ~bug ~project_label" }
      let(:note) { create(:note, noteable: epic, note: note_text) }

      before do
        group.add_developer(user)
      end

      context 'when epics are not enabled' do
        it 'does not add a label to the epic' do
          expect { execute(note) }.not_to change(epic.labels, :count)
        end
      end

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'adds a group label to the epic' do
          expect { execute(note) }.to change { epic.reload.labels.map(&:title) }.to(['bug'])
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end
      end
    end

    describe '/unlabel' do
      let(:project) { nil }
      let!(:bug) { create(:group_label, title: 'bug', group: group) }
      let!(:feature) { create(:group_label, title: 'feature', group: group) }
      let(:note_text) { "/unlabel ~bug" }
      let(:note) { create(:note, noteable: epic, note: note_text) }

      before do
        group.add_developer(user)
        epic.labels = [bug, feature]
      end

      context 'when epics are not enabled' do
        it 'does not remove any label' do
          expect { execute(note) }.not_to change(epic.labels, :count)
        end
      end

      context 'when epics are enabled' do
        before do
          stub_licensed_features(epics: true)
        end

        it 'removes a requested label from the epic' do
          expect { execute(note) }.to change { epic.reload.labels.map(&:title) }.to(['feature'])
        end

        it 'leaves the note empty' do
          expect(execute(note)).to eq('')
        end
      end
    end
  end

  describe '/assign_reviewer' do
    let(:user) { create(:user) }
    let(:note_text) { %(/assign_reviewer @#{user.username} @#{reviewer.username}\n) }

    let(:multiline_assign_reviewer_text) do
      <<~HEREDOC
      /assign_reviewer #{user.to_reference}
      /assign_reviewer #{reviewer.to_reference}
      HEREDOC
    end

    before do
      project.add_maintainer(reviewer)
      project.add_maintainer(user)
    end

    context 'with a merge request' do
      let(:note) { create(:note_on_merge_request, note: note_text, project: project) }

      it_behaves_like 'assigns one or more reviewers to the merge request', multiline: false do
        let(:target) { note.noteable }
      end

      it_behaves_like 'assigns one or more reviewers to the merge request', multiline: true do
        let(:note) { create(:note_on_merge_request, note: multiline_assign_reviewer_text, project: project) }
        let(:target) { note.noteable }
      end
    end
  end

  describe '/assign' do
    let(:user) { create(:user) }
    let(:note_text) { %(/assign @#{user.username} @#{assignee.username}\n) }
    let(:multiline_assign_note_text) { %(/assign @#{user.username}\n/assign @#{assignee.username}) }

    before do
      project.add_maintainer(assignee)
      project.add_maintainer(user)
    end

    context 'Issue assignees' do
      let(:note) { create(:note_on_issue, note: note_text, project: project) }

      it 'adds multiple assignees from the list' do
        _, update_params, message = service.execute(note)
        service.apply_updates(update_params, note)

        expect(message).to eq("Assigned @#{assignee.username} and @#{user.username}.")
        expect(note.noteable.assignees.count).to eq(2)
      end

      it_behaves_like 'assigning an already assigned user', false do
        let(:target) { note.noteable }
      end

      it_behaves_like 'assigning an already assigned user', true do
        let(:note) { create(:note_on_issue, note: multiline_assign_note_text, project: project) }
        let(:target) { note.noteable }
      end
    end

    context 'MergeRequest' do
      let(:note) { create(:note_on_merge_request, note: note_text, project: project) }

      it_behaves_like 'assigning an already assigned user', false do
        let(:target) { note.noteable }
      end

      it_behaves_like 'assigning an already assigned user', true do
        let(:note) { create(:note_on_merge_request, note: multiline_assign_note_text, project: project) }
        let(:target) { note.noteable }
      end
    end
  end

  describe '/unassign' do
    let(:note_text) { %(/unassign @#{assignee.username} @#{user.username}\n) }
    let(:multiline_unassign_note_text) { %(/unassign @#{assignee.username}\n/unassign @#{user.username}) }

    before do
      project.add_maintainer(user)
    end

    context 'Issue assignees' do
      let(:note) { create(:note_on_issue, note: note_text, project: project) }

      it_behaves_like 'unassigning a not assigned user', false do
        let(:target) { note.noteable }
      end

      it_behaves_like 'unassigning a not assigned user', true do
        let(:note) { create(:note_on_issue, note: multiline_unassign_note_text, project: project) }
        let(:target) { note.noteable }
      end
    end

    context 'MergeRequest' do
      let(:note) { create(:note_on_merge_request, note: note_text, project: project) }

      it_behaves_like 'unassigning a not assigned user', false do
        let(:target) { note.noteable }
      end

      it_behaves_like 'unassigning a not assigned user', true do
        let(:note) { create(:note_on_merge_request, note: multiline_unassign_note_text, project: project) }
        let(:target) { note.noteable }
      end
    end
  end

  describe '/unassign_reviewer' do
    let(:note_text) { %(/unassign_reviewer @#{reviewer.username} @#{user.username}\n) }

    let(:multiline_unassign_reviewer_note_text) do
      <<~HEREDOC
      /unassign_reviewer @#{reviewer.username}
      /unassign_reviewer @#{user.username}
      HEREDOC
    end

    before do
      project.add_maintainer(user)
      project.add_maintainer(reviewer)
    end

    context 'with a merge request' do
      let(:note) { create(:note_on_merge_request, note: note_text, project: project) }

      it_behaves_like 'unassigning one or more reviewers', multiline: false do
        let(:target) { note.noteable }
      end

      it_behaves_like 'unassigning one or more reviewers', multiline: true do
        let(:note) { create(:note_on_merge_request, note: multiline_unassign_reviewer_note_text, project: project) }
        let(:target) { note.noteable }
      end
    end
  end

  context '/promote' do
    let(:note_text) { "/promote" }
    let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

    context 'when epics are enabled' do
      before do
        stub_licensed_features(epics: true)
      end

      context 'when a user does not have permissions to promote an issue' do
        it 'does not promote an issue to an epic' do
          expect { execute(note) }.not_to change { Epic.count }
          expect(issue.promoted_to_epic_id).to be_nil
        end
      end

      context 'when a user has permissions to promote an issue' do
        before do
          group.add_developer(user)
        end

        it 'promotes an issue to an epic' do
          expect { execute(note) }.to change { Epic.count }.by(1)
          expect(issue.promoted_to_epic_id).to be_present
        end

        context 'with a double promote' do
          let(:note_text) do
            <<~HEREDOC
            /promote
            /promote
            HEREDOC
          end

          it 'only creates one epic' do
            expect { execute(note) }.to change { Epic.count }.by(1)
          end
        end

        context 'when issue was already promoted' do
          it 'does not promote issue' do
            issue.update!(promoted_to_epic_id: epic.id)

            expect { execute(note) }.not_to change { Epic.count }
          end
        end

        context 'when an issue belongs to a project without group' do
          let(:project) { create(:project) }
          let(:issue) { create(:issue, project: project) }
          let(:note) { create(:note_on_issue, noteable: issue, project: project, note: note_text) }

          before do
            project.add_developer(user)
          end

          it 'does not promote an issue to an epic' do
            expect { execute(note) }.not_to change { Epic.count }
          end
        end

        context 'on an incident' do
          before do
            issue.update!(issue_type: :incident, work_item_type: WorkItems::Type.default_by_type(:incident))
          end

          it 'does not promote to an epic' do
            expect { execute(note) }.not_to change { Epic.count }
          end
        end
      end
    end

    context 'when epics are disabled' do
      it 'does not promote an issue to an epic' do
        group.add_developer(user)

        expect { execute(note) }.not_to change { Epic.count }
      end
    end
  end

  context 'with issue types' do
    shared_examples 'note on issue type that does not support time tracking' do
      let(:note) { build(:note_on_issue, project: project, noteable: noteable) }

      before do
        note.note = note_text
      end

      context '/spend' do
        let(:note_text) { "/spend 1h 2021-05-26" }

        it 'does not change time spent' do
          expect { execute(note) }.not_to change { noteable.reload.time_spent }
        end
      end

      context '/estimate' do
        let(:note_text) { "/estimate 1h" }

        it 'does not execute time estimate' do
          expect { execute(note) }.not_to change { noteable.reload.time_estimate }
        end
      end
    end

    context 'when issue does not support quick actions' do
      before do
        group.add_developer(user)
      end

      context 'for requirement' do
        it_behaves_like 'note on issue type that does not support time tracking' do
          let(:noteable) { create(:requirement_issue, project: project) }
        end
      end

      context 'for test case' do
        it_behaves_like 'note on issue type that does not support time tracking' do
          let(:noteable) { create(:quality_test_case, project: project) }
        end
      end
    end
  end
end
