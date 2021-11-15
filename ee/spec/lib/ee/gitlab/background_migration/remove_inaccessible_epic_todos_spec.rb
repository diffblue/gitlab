# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::RemoveInaccessibleEpicTodos, schema: 20181228175414 do
  include MigrationHelpers::NamespacesHelpers

  let(:users) { table(:users) }
  let(:todos) { table(:todos) }
  let(:epics) { table(:epics) }
  let(:members_table) { table(:members) }
  let(:group_group_links) { table(:group_group_links) }

  let(:author) { users.create!(email: 'author@example.com', projects_limit: 10) }
  let(:user) { users.create!(email: 'user@example.com', projects_limit: 10) }

  let(:group_root) { create_namespace('root', Gitlab::VisibilityLevel::PUBLIC) }
  let(:group_level1) { create_namespace('level1', Gitlab::VisibilityLevel::PUBLIC, parent_id: group_root.id) }

  let(:epic_conf1) { epics.create!(iid: 1, title: 'confidential1', title_html: 'confidential1', confidential: true, group_id: group_root.id, author_id: author.id) }
  let(:epic_conf2) { epics.create!(iid: 1, title: 'confidential2', title_html: 'confidential2', confidential: true, group_id: group_level1.id, author_id: author.id) }
  let(:epic_public1) { epics.create!(iid: 2, title: 'public1', title_html: 'epic_public1', group_id: group_root.id, author_id: author.id) }
  let(:epic_public2) { epics.create!(iid: 2, title: 'public1', title_html: 'epic_public2', group_id: group_level1.id, author_id: author.id) }

  let!(:todo1) { todos.create!(target_type: 'Epic', target_id: epic_conf1.id, user_id: user.id, author_id: user.id, action: 2, state: 0) }
  let!(:todo2) { todos.create!(target_type: 'Epic', target_id: epic_conf2.id, user_id: user.id, author_id: user.id, action: 2, state: 0) }
  let!(:todo3) { todos.create!(target_type: 'Epic', target_id: epic_public1.id, user_id: user.id, author_id: user.id, action: 2, state: 0) }
  let!(:todo4) { todos.create!(target_type: 'Epic', target_id: epic_public2.id, user_id: user.id, author_id: user.id, action: 2, state: 0) }

  describe '#perform' do
    subject(:perform) { described_class.new.perform(epics.first.id, epics.last.id) }

    def expect_todos(preserved:)
      expect { subject }.to change { todos.count }.by(preserved.count - 4)

      existing_ids = todos.pluck(:id)
      expect(existing_ids).to match_array(preserved)
    end

    context 'when user is not member of related groups' do
      it 'deletes only todos referencing confidential epics' do
        expect_todos(preserved: [todo3.id, todo4.id])
      end
    end

    context 'when user is only guest member of related groups' do
      let!(:member) do
        members_table.create!(user_id: user.id, source_id: group_root.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 10, notification_level: 3)
      end

      it 'deletes todos referencing confidential epics' do
        expect_todos(preserved: [todo3.id, todo4.id])
      end
    end

    context 'when user is member of subgroup' do
      let!(:member) do
        members_table.create!(user_id: user.id, source_id: group_level1.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, notification_level: 3)
      end

      it 'deletes only epic todos in the root group' do
        expect_todos(preserved: [todo2.id, todo3.id, todo4.id])
      end
    end

    context 'when user is member of root group' do
      let!(:member) do
        members_table.create!(user_id: user.id, source_id: group_root.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, notification_level: 3)
      end

      it 'does not delete any todos' do
        expect_todos(preserved: [todo1.id, todo2.id, todo3.id, todo4.id])
      end
    end

    context 'when user is only guest on root group' do
      let!(:root_member) do
        members_table.create!(user_id: user.id, source_id: group_root.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 10, notification_level: 3)
      end

      let!(:subgroup_member) do
        members_table.create!(user_id: user.id, source_id: group_level1.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, notification_level: 3)
      end

      it 'deletes only root confidential epic todo' do
        expect_todos(preserved: [todo2.id, todo3.id, todo4.id])
      end
    end

    context 'when root group is shared with other group' do
      let!(:other_group) { create_namespace('other_group', Gitlab::VisibilityLevel::PRIVATE) }
      let!(:member) do
        members_table.create!(user_id: user.id, source_id: other_group.id, source_type: 'Namespace',
                              type: 'GroupMember', access_level: 20, notification_level: 3)
      end

      let!(:group_link) do
        group_group_links.create!(shared_group_id: group_root.id,
                                  shared_with_group_id: other_group.id, group_access: 20)
      end

      it 'does not delete any todos' do
        expect_todos(preserved: [todo1.id, todo2.id, todo3.id, todo4.id])
      end
    end
  end
end
