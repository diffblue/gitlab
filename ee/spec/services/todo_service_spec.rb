# frozen_string_literal: true

require 'spec_helper'

RSpec.describe TodoService, feature_category: :team_planning do
  let_it_be(:author) { create(:user, username: 'author') }
  let_it_be(:non_member) { create(:user, username: 'non_member') }
  let_it_be(:member) { create(:user, username: 'member') }
  let_it_be(:guest) { create(:user, username: 'guest') }
  let_it_be(:admin) { create(:admin, username: 'administrator') }
  let_it_be(:john_doe) { create(:user, username: 'john_doe') }
  let_it_be(:skipped) { create(:user, username: 'skipped') }

  let(:skip_users) { [skipped] }
  let(:service) { described_class.new }

  describe 'Epics' do
    let(:users) { [author, non_member, member, guest, admin, john_doe, skipped] }
    let(:mentions) { users.map(&:to_reference).join(' ') }
    let(:combined_mentions) { member.to_reference + ", what do you think? cc: " + [guest, admin, skipped].map(&:to_reference).join(' ') }

    let(:description_mentions) { "- [ ] Task 1\n- [ ] Task 2 FYI: #{mentions}" }
    let(:description_directly_addressed) { "#{mentions}\n- [ ] Task 1\n- [ ] Task 2" }

    let_it_be(:group, reload: true) { create(:group) }

    let(:epic) { create(:epic, group: group, author: author, description: description_mentions) }

    let(:todos_for) { [] }
    let(:todos_not_for) { [] }
    let(:target) { epic }

    before_all do
      group.add_guest(guest)
      group.add_developer(author)
      group.add_developer(member)
    end

    before do
      stub_licensed_features(epics: true)
    end

    shared_examples_for 'todos creation' do
      it 'creates todos for users mentioned' do
        if todos_for.count > 0
          params = todo_params
            .merge(user: todos_for)
            .reverse_merge(target: target, project: nil, group: group, author: author, state: :pending)

          expect { execute }
            .to change { Todo.where(params).count }.from(0).to(todos_for.count)
        end
      end

      it 'does not create todos for users not mentioned or without permissions' do
        execute

        params = todo_params
          .reverse_merge(target: target, project: nil, group: group, author: author, state: :pending)

        todos_not_for.each_with_index do |user, index|
          expect(Todo.where(params.merge(user: user)).count)
            .to eq(0), "expected not to create a todo for user '#{user.username}''"
        end
      end
    end

    context 'Epics' do
      describe '#new_epic' do
        let(:execute) { service.new_epic(epic, author) }

        context 'when an epic belongs to a public group' do
          context 'for mentioned users' do
            let(:todo_params) { { action: Todo::MENTIONED } }
            let(:todos_for) { users }

            include_examples 'todos creation'
          end

          context 'for directly addressed users' do
            before do
              epic.update!(description: description_directly_addressed)
            end

            let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
            let(:todos_for) { users }

            include_examples 'todos creation'
          end

          context 'combined' do
            before do
              epic.update!(description: combined_mentions)
            end

            context 'mentioned users' do
              let(:todo_params) { { action: Todo::MENTIONED } }
              let(:todos_for) { [guest, admin, skipped] }

              include_examples 'todos creation'
            end

            context 'directly addressed users' do
              let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
              let(:todos_for) { [member] }

              include_examples 'todos creation'
            end
          end
        end

        context 'when an epic belongs to a private group' do
          before do
            group.update!(visibility: Gitlab::VisibilityLevel::PRIVATE)
          end

          context 'for mentioned users' do
            let(:todo_params) { { action: Todo::MENTIONED } }
            let(:todos_for) { [member, author, guest] }
            let(:todos_not_for) { [non_member, john_doe, skipped] }

            include_examples 'todos creation'
          end

          context 'for directly addressed users' do
            before do
              epic.update!(description: description_directly_addressed)
            end

            let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
            let(:todos_for) { [member, author, guest] }
            let(:todos_not_for) { [non_member, john_doe, skipped] }

            include_examples 'todos creation'
          end
        end

        context 'creates todos for group members when a group is mentioned' do
          before do
            epic.update!(description: group.to_reference)
          end

          let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
          let(:todos_for) { [member, guest, author] }
          let(:todos_not_for) { [non_member, admin, john_doe] }

          include_examples 'todos creation'
        end
      end

      describe '#update_epic' do
        let(:execute) { service.update_epic(epic, author, skip_users) }

        context 'for mentioned users' do
          let(:todo_params) { { action: Todo::MENTIONED } }
          let(:todos_for) { [author, non_member, member, guest, admin, john_doe] }
          let(:todos_not_for) { [skipped] }

          include_examples 'todos creation'
        end

        context 'for directly addressed users' do
          before do
            epic.update!(description: description_directly_addressed)
          end

          let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
          let(:todos_for) { [author, non_member, member, guest, admin, john_doe] }
          let(:todos_not_for) { [skipped] }

          include_examples 'todos creation'
        end

        context 'when toggling task list items' do
          before do
            epic.update!(description: "- [x] Task 1\n- [x] Task 2 FYI: #{mentions}")
          end

          it 'does not create todos' do
            expect { execute }.not_to change { Todo.count }
          end
        end
      end

      describe '#new_note' do
        let(:note) { create(:note, noteable: epic, project: nil, author: john_doe, note: mentions) }

        context 'when a note is created for an epic' do
          let!(:first_todo) do
            create(:todo, :assigned,
              user: john_doe, project: nil, group: group, target: epic, author: author)
          end

          let!(:second_todo) do
            create(:todo, :assigned,
              user: john_doe, project: nil, group: group, target: epic, author: author)
          end

          it 'marks pending epic todos for the note author as done' do
            service.new_note(note, john_doe)

            expect(first_todo.reload).to be_done
            expect(second_todo.reload).to be_done
          end

          it 'does not mark pending epic todos for the note author as done for system notes' do
            system_note = create(:system_note, noteable: epic)

            service.new_note(system_note, john_doe)

            expect(first_todo.reload).to be_pending
            expect(second_todo.reload).to be_pending
          end
        end

        context 'mentions' do
          let(:execute) { service.new_note(note, author) }

          context 'for mentioned users' do
            before do
              note.update!(note: description_mentions)
            end

            let(:todo_params) { { action: Todo::MENTIONED } }
            let(:todos_for) { users }
            let(:todos_not_for) { [] }

            include_examples 'todos creation'
          end

          context 'for directly addressed users' do
            before do
              note.update!(note: description_directly_addressed)
            end

            let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
            let(:todos_for) { users }
            let(:todos_not_for) { [] }

            include_examples 'todos creation'
          end

          context 'combined' do
            before do
              note.update!(note: combined_mentions)
            end

            context 'mentioned users' do
              let(:todo_params) { { action: Todo::MENTIONED } }
              let(:todos_for) { [guest, admin, skipped] }

              include_examples 'todos creation'
            end

            context 'directly addressed users' do
              let(:todo_params) { { action: Todo::DIRECTLY_ADDRESSED } }
              let(:todos_for) { [member] }

              include_examples 'todos creation'
            end
          end
        end
      end
    end
  end

  context 'Merge Requests' do
    let(:project) { create(:project, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project, author: author, description: description) }

    let(:assignee) { create(:user) }
    let(:approver_1) { create(:user) }
    let(:approver_2) { create(:user) }
    let(:approver_3) { create(:user) }
    let(:code_owner) { create(:user, username: 'codeowner') }
    let(:description) { 'FYI: ' + [john_doe, approver_1].map(&:to_reference).join(' ') }
    let(:no_todo_for_approvers_ff_enabled) { false }

    before do
      stub_feature_flags(no_todo_for_approvers: no_todo_for_approvers_ff_enabled)

      project.add_guest(guest)
      project.add_developer(author)
      project.add_developer(member)
      project.add_developer(john_doe)
      project.add_developer(skipped)
      project.add_developer(approver_1)
      project.add_developer(approver_2)
      project.add_developer(approver_3)
      project.add_developer(code_owner)

      create(:approver, user: approver_1, target: project)
      create(:approver, user: approver_2, target: project)

      allow(merge_request).to receive(:code_owners).and_return([code_owner])

      service.new_merge_request(merge_request, author)
    end

    shared_examples 'when user is mentioned' do
      it 'creates a todo' do
        # for each valid mentioned user

        should_create_todo(user: john_doe, target: merge_request, action: Todo::MENTIONED)
      end
    end

    shared_examples 'when code owner is not mentioned' do
      it 'skips creating a todo' do
        # skip for code owner
        should_not_create_todo(user: code_owner, target: merge_request, action: Todo::APPROVAL_REQUIRED)
      end
    end

    shared_examples 'when code owner is mentioned' do
      let(:description) { 'FYI: ' + [code_owner].map(&:to_reference).join(' ') }
      it 'creates a todo' do
        should_create_todo(user: code_owner, target: merge_request, action: Todo::MENTIONED)
      end
    end

    describe '#new_merge_request' do
      context 'when the merge request has approvers' do
        context 'when no_todo_for_approvers feature flag is disabled' do
          let(:no_todo_for_approvers_ff_enabled) { false }

          it 'creates a approval required todo for added approvers', :aggregate_failures do
            # for each approver
            should_create_todo(user: approver_1, target: merge_request, action: Todo::APPROVAL_REQUIRED)
            should_create_todo(user: approver_2, target: merge_request, action: Todo::APPROVAL_REQUIRED)
            should_not_create_todo(user: approver_3, target: merge_request, action: Todo::APPROVAL_REQUIRED)
          end

          it_behaves_like 'when user is mentioned'
          it_behaves_like 'when code owner is not mentioned'
          it_behaves_like 'when code owner is mentioned'
        end

        context 'when no_todo_for_approvers feature flag is enabled' do
          let(:no_todo_for_approvers_ff_enabled) { true }

          it 'skips creating a approval required todo', :aggregate_failures do
            # for each approver
            should_not_create_todo(user: approver_1, target: merge_request, action: Todo::APPROVAL_REQUIRED)
            should_not_create_todo(user: approver_2, target: merge_request, action: Todo::APPROVAL_REQUIRED)
            should_not_create_todo(user: approver_3, target: merge_request, action: Todo::APPROVAL_REQUIRED)
          end

          it_behaves_like 'when user is mentioned'
          it_behaves_like 'when code owner is not mentioned'
          it_behaves_like 'when code owner is mentioned'
        end
      end
    end
  end

  context 'Merge Requests' do
    let(:project) { create(:project, :private, :repository) }
    let(:merge_request) { create(:merge_request, source_project: project, author: author) }

    context 'an approver has lost access to the project', :sidekiq_inline do
      before do
        create(:approver, user: non_member, target: project)
        project.members.find_by(user_id: non_member.id).destroy!
      end

      describe '#new_merge_request' do
        it 'does not create a todo for the approver' do
          service.new_merge_request(merge_request, author)

          should_not_create_todo(user: non_member, target: merge_request, action: Todo::APPROVAL_REQUIRED)
        end
      end
    end

    describe '#merge_train_removed' do
      let(:merge_participants) { [admin, create(:user)] }

      before do
        allow(merge_request).to receive(:merge_participants).and_return(merge_participants)
      end

      it 'creates a pending todo for each merge_participant' do
        merge_request.update!(merge_when_pipeline_succeeds: true, merge_user: admin)
        service.merge_train_removed(merge_request)

        merge_participants.each do |participant|
          should_create_todo(user: participant, author: participant, target: merge_request, action: Todo::MERGE_TRAIN_REMOVED)
        end
      end
    end
  end

  def should_create_todo(attributes = {})
    attributes.reverse_merge!(
      project: project,
      author: author,
      state: :pending
    )

    expect(Todo.where(attributes).count).to eq 1
  end

  def should_not_create_todo(attributes = {})
    attributes.reverse_merge!(
      project: project,
      author: author,
      state: :pending
    )

    expect(Todo.where(attributes).count).to eq 0
  end
end
