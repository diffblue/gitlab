# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Epics::UpdateService, feature_category: :portfolio_management do
  let(:group) { create(:group, :internal) }
  let(:user) { create(:user) }
  let(:epic) { create(:epic, group: group) }

  describe '#execute' do
    before do
      stub_licensed_features(epics: true, subepics: true)
      group.add_maintainer(user)
    end

    def find_note(starting_with)
      epic.notes.find do |note|
        note && note.note.start_with?(starting_with)
      end
    end

    def find_notes(action)
      epic
        .notes
        .joins(:system_note_metadata)
        .where(system_note_metadata: { action: action })
    end

    def update_epic(opts)
      described_class.new(group: group, current_user: user, params: opts).execute(epic)
    end

    it_behaves_like 'issuable update service updating last_edited_at values' do
      let(:issuable) { epic }
      subject(:update_issuable) { update_epic(update_params) }
    end

    context 'multiple values update' do
      let(:opts) do
        {
          title: 'New title',
          description: 'New description',
          start_date_fixed: '2017-01-09',
          start_date_is_fixed: true,
          due_date_fixed: '2017-10-21',
          due_date_is_fixed: true,
          state_event: 'close',
          confidential: true
        }
      end

      it 'updates the epic correctly' do
        update_epic(opts)

        expect(epic).to be_valid
        expect(epic).to have_attributes(opts.except(:due_date_fixed, :start_date_fixed))
        expect(epic).to have_attributes(
          start_date_fixed: Date.strptime(opts[:start_date_fixed]),
          due_date_fixed: Date.strptime(opts[:due_date_fixed]),
          confidential: true
        )
        expect(epic).to be_closed
      end
    end

    context 'when title has changed' do
      it 'creates system note about title change' do
        expect { update_epic(title: 'New title') }.to change { Note.count }.from(0).to(1)

        note = Note.last

        expect(note.note).to start_with('changed title')
        expect(note.noteable).to eq(epic)
      end

      it 'records epic title changed after saving' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_title_changed_action).with(author: user, namespace: group)

        update_epic(title: 'New title')
      end
    end

    context 'when description has changed' do
      it 'creates system note about description change' do
        expect { update_epic(description: 'New description') }.to change { Note.count }.from(0).to(1)

        note = Note.last

        expect(note.note).to start_with('changed the description')
        expect(note.noteable).to eq(epic)
      end

      it 'records epic description changed after saving' do
        expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_description_changed_action).with(author: user, namespace: group)

        update_epic(description: 'New description')
      end

      it 'triggers GraphQL description updated subscription' do
        expect(GraphqlTriggers).to receive(:issuable_description_updated).with(epic).and_call_original

        update_epic(description: 'updated description')
      end
    end

    context 'when decription is not changed' do
      it 'does not trigger GraphQL description updated subscription' do
        expect(GraphqlTriggers).not_to receive(:issuable_description_updated)

        update_epic(title: 'updated title')
      end
    end

    context 'when repositioning an epic on a board' do
      let_it_be(:group) { create(:group) }
      let_it_be(:epic) { create(:epic, group: group) }
      let_it_be_with_reload(:epic1) { create(:epic, group: group) }
      let_it_be_with_reload(:epic2) { create(:epic, group: group) }
      let_it_be_with_reload(:epic3) { create(:epic, group: group) }

      let_it_be(:board) { create(:epic_board, group: group) }
      let_it_be(:list) { create(:epic_list, epic_board: board, list_type: :backlog) }

      def position(epic)
        epic.epic_board_positions.first&.relative_position
      end

      before do
        group.add_maintainer(user)
      end

      shared_examples 'board repositioning' do
        context 'when moving between 2 epics on the board' do
          subject { update_epic(move_between_ids: [epic2.id, epic1.id], board_id: board.id, list_id: list.id, board_group: group) }

          it 'moves the epic correctly' do
            subject

            expect(position(epic)).to be > position(epic2)

            # we don't create the position for epic below if it does not exist before the positioning
            expect(position(epic)).to be < position(epic1) if position(epic1)
          end
        end

        context 'when moving the epic to the end' do
          it 'moves the epic correctly' do
            update_epic(move_between_ids: [epic2.id, nil], board_id: board.id, list_id: list.id, board_group: group)

            expect(position(epic)).to be > position(epic2)
          end
        end
      end

      context 'when board position records exist for all epics' do
        let_it_be_with_reload(:epic_position) { create(:epic_board_position, epic: epic, epic_board: board, relative_position: 1) }
        let_it_be_with_reload(:epic1_position) { create(:epic_board_position, epic: epic1, epic_board: board, relative_position: 30) }
        let_it_be_with_reload(:epic2_position) { create(:epic_board_position, epic: epic2, epic_board: board, relative_position: 20) }
        let_it_be_with_reload(:epic3_position) { create(:epic_board_position, epic: epic3, epic_board: board, relative_position: 10) }

        it_behaves_like 'board repositioning'

        context 'when moving beetween 2 epics on the board' do
          it 'keeps epic3 on top of the board' do
            update_epic(move_between_ids: [epic2.id, epic1.id], board_id: board.id, list_id: list.id, board_group: group)

            expect(position(epic3)).to be < position(epic2)
            expect(position(epic3)).to be < position(epic1)
          end
        end

        context 'when moving the epic to the beginning' do
          before do
            epic_position.update_column(:relative_position, 25)
          end

          it 'moves the epic correctly' do
            update_epic(move_between_ids: [nil, epic3.id], board_id: board.id, list_id: list.id, board_group: group)

            expect(epic_position.reload.relative_position).to be < epic3_position.relative_position
          end
        end

        context 'when moving the epic to the end' do
          it 'keeps epic3 on top of the board' do
            update_epic(move_between_ids: [epic1.id, nil], board_id: board.id, list_id: list.id, board_group: group)

            expect(position(epic3)).to be < position(epic2)
            expect(position(epic3)).to be < position(epic1)
          end
        end
      end

      context 'when board position records are missing' do
        context 'when the position does not exist for any record' do
          it_behaves_like 'board repositioning'

          context 'when the list is closed' do
            let_it_be(:list) { create(:epic_list, epic_board: board, list_type: :closed) }

            before do
              epic1.update!(state: :closed)
              epic2.update!(state: :closed)
              epic3.update!(state: :closed)
            end

            it_behaves_like 'board repositioning'
          end
        end

        context 'when the epic is in a subgroup' do
          let(:subgroup) { create(:group, parent: group) }
          let(:epic) { create(:epic, group: subgroup) }

          it_behaves_like 'board repositioning'
        end

        context 'when the position does not exist for the record being moved' do
          let_it_be_with_reload(:epic1_position) { create(:epic_board_position, epic: epic1, epic_board: board, relative_position: 30) }
          let_it_be_with_reload(:epic2_position) { create(:epic_board_position, epic: epic2, epic_board: board, relative_position: 20) }

          it_behaves_like 'board repositioning'
        end

        context 'when the position exists for the above and moving records but not for higher ids' do
          let_it_be_with_reload(:epic2_position) { create(:epic_board_position, epic: epic2, epic_board: board, relative_position: 30) }
          let_it_be_with_reload(:epic_position) { create(:epic_board_position, epic: epic, epic_board: board, relative_position: 10) }

          subject { update_epic(move_between_ids: [epic2.id, epic1.id], board_id: board.id, list_id: list.id, board_group: group) }

          it 'moves the epic correctly' do
            subject

            expect(position(epic)).to be > position(epic2)
          end

          it 'does not create new position records' do
            expect { subject }.not_to change { Boards::EpicBoardPosition.count }
          end
        end

        context 'when the position does not exist for the records around the one being moved' do
          let_it_be_with_reload(:epic_position) { create(:epic_board_position, epic: epic, epic_board: board, relative_position: 10) }

          it_behaves_like 'board repositioning'
        end
      end
    end

    context 'after_save callback to store_mentions' do
      let(:user2) { create(:user) }
      let(:epic) { create(:epic, group: group, description: "simple description") }
      let(:labels) { create_pair(:group_label, group: group) }

      context 'when mentionable attributes change' do
        let(:opts) { { description: "Description with #{user.to_reference}" } }

        it 'saves mentions' do
          expect(epic).to receive(:store_mentions!).and_call_original

          expect { update_epic(opts) }.to change { EpicUserMention.count }.by(1)

          expect(epic.referenced_users).to match_array([user])
        end
      end

      context 'when mentionable attributes do not change' do
        let(:opts) { { label_ids: labels.map(&:id) } }

        it 'does not call store_mentions!' do
          expect(epic).not_to receive(:store_mentions!).and_call_original

          expect { update_epic(opts) }.not_to change { EpicUserMention.count }

          expect(epic.referenced_users).to be_empty
        end
      end

      context 'when save fails' do
        let(:opts) { { title: '', label_ids: labels.map(&:id) } }

        it 'does not call store_mentions!' do
          expect(epic).not_to receive(:store_mentions!).and_call_original

          expect { update_epic(opts) }.not_to change { EpicUserMention.count }

          expect(epic.referenced_users).to be_empty
          expect(epic.valid?).to be false
        end
      end
    end

    context 'todos' do
      before do
        group.update!(visibility: Gitlab::VisibilityLevel::PUBLIC)
      end

      context 'creating todos' do
        let(:mentioned1) { create(:user) }
        let(:mentioned2) { create(:user) }

        before do
          epic.update!(description: "FYI: #{mentioned1.to_reference}")
        end

        it 'creates todos for only newly mentioned users' do
          expect do
            update_epic(description: "FYI: #{mentioned1.to_reference} #{mentioned2.to_reference}")
          end.to change { Todo.count }.by(1)
        end
      end

      context 'adding a label' do
        let(:label) { create(:group_label, group: group) }
        let(:user2) { create(:user) }
        let!(:todo1) do
          create(:todo, :mentioned, :pending,
            target: epic,
            group: group,
            project: nil,
            author: user,
            user: user)
        end

        let!(:todo2) do
          create(:todo, :mentioned, :pending,
            target: epic,
            group: group,
            project: nil,
            author: user2,
            user: user2)
        end

        subject { update_epic(label_ids: [label.id]) }

        before do
          group.add_developer(user)
        end

        it 'marks todo as done for a user who added a label' do
          subject

          expect(todo1.reload.state).to eq('done')
        end

        it 'does not mark todos as done for other users' do
          subject

          expect(todo2.reload.state).to eq('pending')
        end

        it 'tracks the label change' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
            .to receive(:track_epic_labels_changed_action).with(author: user, namespace: group)

          subject
        end
      end

      context 'mentioning a group in epic description' do
        let(:mentioned1) { create(:user) }
        let(:mentioned2) { create(:user) }

        before do
          group.add_developer(mentioned1)
          epic.update!(description: "FYI: #{group.to_reference}")
        end

        context 'when the group is public' do
          before do
            group.update!(visibility: Gitlab::VisibilityLevel::PUBLIC)
          end

          it 'creates todos for only newly mentioned users' do
            expect do
              update_epic(description: "FYI: #{mentioned1.to_reference} #{mentioned2.to_reference}")
            end.to change { Todo.count }.by(1)
          end
        end

        context 'when the group is private' do
          before do
            group.update!(visibility: Gitlab::VisibilityLevel::PRIVATE)
          end

          it 'creates todos for only newly mentioned users that are group members' do
            expect do
              update_epic(description: "FYI: #{mentioned1.to_reference} #{mentioned2.to_reference}")
            end.to not_change { Todo.count }
          end
        end
      end

      context 'when the epic becomes confidential' do
        it 'schedules deletion of todos' do
          expect(TodosDestroyer::ConfidentialEpicWorker).to receive(:perform_in).with(Todo::WAIT_FOR_DELETE, epic.id)

          update_epic(confidential: true)
        end

        it 'tracks the epic becoming confidential' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
            .to receive(:track_epic_confidential_action).with(author: user, namespace: group)

          update_epic(confidential: true)
        end
      end

      context 'when the epic becomes visible' do
        before do
          epic.update_column(:confidential, true)
        end

        it 'does not schedule deletion of todos' do
          expect(TodosDestroyer::ConfidentialEpicWorker).not_to receive(:perform_in)

          update_epic(confidential: false)
        end

        it 'tracks the epic becoming visible' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
            .to receive(:track_epic_visible_action).with(author: user, namespace: group)

          update_epic(confidential: false)
        end
      end
    end

    context 'when Epic has tasks' do
      before do
        update_epic(description: "- [ ] Task 1\n- [ ] Task 2")
      end

      it { expect(epic.tasks?).to eq(true) }

      it_behaves_like 'updating a single task' do
        def update_issuable(opts)
          described_class.new(group: group, current_user: user, params: opts).execute(epic)
        end
      end

      context 'when tasks are marked as completed' do
        it 'creates system note about task status change' do
          update_epic(description: "- [x] Task 1\n- [X] Task 2")

          note1 = find_note('marked the checklist item **Task 1** as completed')
          note2 = find_note('marked the checklist item **Task 2** as completed')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil

          description_notes = find_notes('description')
          expect(description_notes.length).to eq(1)
        end

        it 'counts the change correctly' do
          expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_task_checked)
            .with(author: user, namespace: group).twice

          update_epic(description: "- [x] Task 1\n- [X] Task 2")
        end
      end

      context 'when tasks are marked as incomplete' do
        before do
          update_epic(description: "- [x] Task 1\n- [X] Task 2")
        end

        it 'creates system note about task status change' do
          update_epic(description: "- [ ] Task 1\n- [ ] Task 2")

          note1 = find_note('marked the checklist item **Task 1** as incomplete')
          note2 = find_note('marked the checklist item **Task 2** as incomplete')

          expect(note1).not_to be_nil
          expect(note2).not_to be_nil

          description_notes = find_notes('description')
          expect(description_notes.length).to eq(1)
        end

        it 'counts the change correctly' do
          expect(Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_task_unchecked)
            .with(author: user, namespace: group).twice

          update_epic(description: "- [ ] Task 1\n- [ ] Task 2")
        end
      end
    end

    context 'filter out start_date and end_date' do
      it 'ignores start_date and end_date' do
        expect { update_epic(start_date: Date.today, end_date: Date.today) }.not_to change { Note.count }

        expect(epic).to be_valid
        expect(epic).to have_attributes(start_date: nil, due_date: nil)
      end
    end

    context 'refresh epic dates' do
      context 'date fields are updated' do
        it 'calls UpdateDatesService' do
          expect(Epics::UpdateDatesService).to receive(:new).with([epic]).and_call_original

          update_epic(start_date_is_fixed: true, start_date_fixed: Date.today)
          epic.reload
          expect(epic.start_date).to eq(epic.start_date_fixed)
        end
      end

      context 'epic start date fixed or inherited' do
        it 'tracks the user action to set as fixed' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_start_date_set_as_fixed_action)
            .with(author: user, namespace: group)

          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_fixed_start_date_updated_action)
            .with(author: user, namespace: group)

          update_epic(start_date_is_fixed: true, start_date_fixed: Date.today)
        end

        it 'tracks the user action to set as inherited' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_start_date_set_as_inherited_action)
            .with(author: user, namespace: group)

          update_epic(start_date_is_fixed: false)
        end
      end

      context 'epic due date fixed or inherited' do
        it 'tracks the user action to set as fixed' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_due_date_set_as_fixed_action)
            .with(author: user, namespace: group)

          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_fixed_due_date_updated_action)
            .with(author: user, namespace: group)

          update_epic(due_date_is_fixed: true, due_date_fixed: Date.today)
        end

        it 'tracks the user action to set as inherited' do
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_due_date_set_as_inherited_action)
            .with(author: user, namespace: group)

          update_epic(due_date_is_fixed: false)
        end
      end

      context 'date fields are not updated' do
        it 'does not call UpdateDatesService' do
          expect(Epics::UpdateDatesService).not_to receive(:new)

          update_epic(title: 'foo')
        end
      end
    end

    it_behaves_like 'existing issuable with scoped labels' do
      let(:issuable) { epic }
      let(:parent) { group }
    end

    context 'labels are updated' do
      let(:label_a) { create(:group_label, title: 'a', group: group) }
      let(:label_b) { create(:group_label, title: 'b', group: group) }
      let(:issuable) { epic }

      it_behaves_like 'keeps issuable labels sorted after update'
      it_behaves_like 'broadcasting issuable labels updates'

      def update_issuable(update_params)
        update_epic(update_params)
      end
    end

    context 'with quick actions in the description' do
      before do
        stub_licensed_features(epics: true, subepics: true)
        group.add_developer(user)
      end

      context 'for /label' do
        let(:label) { create(:group_label, group: group) }

        it 'adds labels to the epic' do
          update_epic(description: "/label ~#{label.name}")

          expect(epic.label_ids).to contain_exactly(label.id)
        end
      end

      context 'for /parent_epic' do
        it 'assigns parent epic' do
          parent_epic = create(:epic, group: epic.group)
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_parent_updated_action)
            .with(author: user, namespace: group)

          update_epic(description: "/parent_epic #{parent_epic.to_reference}")

          expect(epic.parent).to eq(parent_epic)
        end

        context 'when parent epic cannot be assigned' do
          it 'does not update parent epic' do
            other_group = create(:group, :private)
            parent_epic = create(:epic, group: other_group)
            expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_parent_updated_action)

            update_epic(description: "/parent_epic #{parent_epic.to_reference(group)}")

            expect(epic.parent).to eq(nil)
          end
        end
      end

      context 'for /child_epic' do
        it 'sets a child epic' do
          child_epic = create(:epic, group: group)
          expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).to receive(:track_epic_parent_updated_action)
            .with(author: user, namespace: group)

          update_epic(description: "/child_epic #{child_epic.to_reference}")

          expect(epic.reload.children).to include(child_epic)
        end

        context 'when child epic cannot be assigned' do
          it 'does not set child epic' do
            other_group = create(:group, :private)
            child_epic = create(:epic, group: other_group)
            expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter).not_to receive(:track_epic_parent_updated_action)

            update_epic(description: "/child_epic #{child_epic.to_reference(group)}")
            expect(epic.reload.children).to be_empty
          end
        end
      end
    end

    context 'when updating parent' do
      let(:new_parent) { create(:epic, group: group) }

      subject { update_epic(parent: new_parent) }

      context 'when user cannot update parent' do
        shared_examples 'updates epic without changing parent' do
          it 'does not change parent' do
            expect { subject }.not_to change { epic.parent }
          end

          it 'does not create notes or track change' do
            expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
              .not_to receive(:track_epic_parent_updated_action)

            expect { subject }.not_to change { Note.count }
          end
        end

        context 'when subepics are disabled' do
          before do
            stub_licensed_features(epics: true, subepics: false)
          end

          it_behaves_like 'updates epic without changing parent'
        end

        context 'when user lacks admin_epic_tree_relation permissions' do
          before do
            allow(Ability).to receive(:allowed?).and_call_original
            allow(Ability).to receive(:allowed?)
              .with(user, :admin_epic_tree_relation, new_parent).and_return(false)
          end

          it_behaves_like 'updates epic without changing parent'

          context 'when using parent_id' do
            subject { update_epic(parent_id: new_parent.id) }

            it 'does not change parent' do
              expect { subject }.not_to change { epic.parent }
            end
          end
        end
      end

      context 'when user can update parent' do
        shared_examples 'records parent changed after saving' do
          it 'tracks parent change' do
            expect(::Gitlab::UsageDataCounters::EpicActivityUniqueCounter)
              .to receive(:track_epic_parent_updated_action)
                    .with(author: user, namespace: group)

            subject
          end
        end

        it 'creates system notes' do
          expect { subject }.to change { epic.parent }.from(nil).to(new_parent)
                                                      .and change { Note.count }.by(2)

          child_ref = epic.to_reference(group)
          new_ref = new_parent.to_reference(group)

          epic.reload
          expect(epic.notes.first.note).to eq("added epic #{new_ref} as parent epic")
          expect(new_parent.notes.first.note).to eq("added epic #{child_ref} as child epic")
        end

        it_behaves_like 'records parent changed after saving'

        context 'when parent is already present' do
          let(:existing_parent) { create(:epic, group: group) }

          before do
            epic.update!(parent: existing_parent)
          end

          it 'changes parent and creates system notes' do
            expect { subject }.to change { epic.parent }.from(existing_parent).to(new_parent)
                                                        .and change { Note.count }.by(3)

            child_ref = epic.to_reference(group)
            new_ref = new_parent.to_reference(group)

            epic.reload
            expect(epic.notes.first.note).to eq("added epic #{new_ref} as parent epic")
            expect(new_parent.notes.first.note).to eq("added epic #{child_ref} as child epic")
            expect(existing_parent.notes.first.note).to eq("moved child epic #{child_ref} to epic #{new_ref}")
          end

          it_behaves_like 'records parent changed after saving'

          context 'when removing parent' do
            subject { update_epic(parent: nil) }

            it 'removed parent and creates system notes' do
              expect { subject }.to change { epic.parent }.from(existing_parent).to(nil)
                                                          .and change { Note.count }.by(2)

              child_ref = epic.to_reference(group)
              existing_ref = existing_parent.to_reference(group)

              epic.reload
              expect(epic.notes.first.note).to eq("removed parent epic #{existing_ref}")
              expect(existing_parent.notes.first.note).to eq("removed child epic #{child_ref}")
            end

            it_behaves_like 'records parent changed after saving'
          end
        end
      end
    end
  end
end
