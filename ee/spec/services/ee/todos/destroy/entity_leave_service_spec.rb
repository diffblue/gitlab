# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Todos::Destroy::EntityLeaveService, feature_category: :team_planning do
  let_it_be(:user) { create(:user) }
  let_it_be(:group) { create(:group) }
  let_it_be(:subgroup) { create(:group, parent: group) }

  let_it_be(:epic1) { create(:epic, confidential: true, group: subgroup) }
  let_it_be(:epic2) { create(:epic, group: subgroup) }

  let!(:todo1) { create(:todo, target: epic1, user: user, group: subgroup) }
  let!(:todo2) { create(:todo, target: epic2, user: user, group: subgroup) }
  let(:internal_note) { create(:note, noteable: epic2, confidential: true ) }
  let!(:todo_for_internal_note) do
    create(:todo, user: user, target: epic2, group: subgroup, note: internal_note)
  end

  describe '#execute' do
    subject { described_class.new(user.id, subgroup.id, 'Group').execute }

    shared_examples 'removes confidential epics and internal notes todos' do
      it 'removes todos targeting confidential epics and internal notes in the group' do
        expect { subject }.to change { Todo.count }.by(-2)
        expect(user.reload.todos.ids).to match_array(todo2.id)
      end
    end

    it_behaves_like 'removes confidential epics and internal notes todos'

    context 'when user is still member of ancestor group' do
      before do
        group.add_reporter(user)
      end

      it 'does not remove todos targeting confidential epics in the group' do
        expect { subject }.not_to change { Todo.count }
      end
    end

    context 'when user was a member of public group with private subgroup' do
      let_it_be(:epic3) { create(:epic, group: group) }

      let!(:todo1) { create(:todo, target: epic3, user: user, group: group) }

      before do
        group.update!(visibility_level: Gitlab::VisibilityLevel::PUBLIC)
        subgroup.update!(visibility_level: Gitlab::VisibilityLevel::PRIVATE)
      end

      it 'removes epic todos from private subgroup' do
        described_class.new(user.id, group.id, 'Group').execute

        expect(user.reload.todos.ids).to match_array(todo1.id)
      end
    end

    context 'when user role is downgraded to guest' do
      before do
        subgroup.add_guest(user)
      end

      it_behaves_like 'removes confidential epics and internal notes todos'
    end
  end
end
