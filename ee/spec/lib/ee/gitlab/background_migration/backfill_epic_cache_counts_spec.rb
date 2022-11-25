# frozen_string_literal: true
require 'spec_helper'

# rubocop:disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::BackgroundMigration::BackfillEpicCacheCounts, :migration do
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:epics) { table(:epics) }
  let(:issues) { table(:issues) }
  let(:epic_issues) { table(:epic_issues) }
  let(:updated_at) { 2.days.ago.round }

  let(:issue_base_type_enum_value) { 0 }
  let(:issue_type) { table(:work_item_types).find_by!(namespace_id: nil, base_type: issue_base_type_enum_value) }

  let!(:root_group) do
    namespaces.create!(name: 'root-group', path: 'root-group', type: 'Group').tap do |new_group|
      new_group.update!(traversal_ids: [new_group.id])
    end
  end

  let!(:group) do
    namespaces.create!(name: 'group', path: 'group', parent_id: root_group.id, type: 'Group') do |new_group|
      new_group.update!(traversal_ids: [root_group.id, new_group.id])
    end
  end

  let!(:project_root) do
    projects.create!(namespace_id: root_group.id, project_namespace_id: root_group.id,
                     name: 'root group project', path: 'root-group-project')
  end

  let!(:project) do
    projects.create!(namespace_id: group.id, project_namespace_id: group.id,
                     name: 'group project', path: 'group-project')
  end

  let!(:epic_root) do
    epics.create!(iid: 2, title: 'root-group-epic', title_html: 'root-group-epic',
                  group_id: root_group.id, author_id: user.id, updated_at: updated_at)
  end

  let!(:epic1) do
    epics.create!(iid: 1, title: 'group-epic1', title_html: 'group-epic1',
                  group_id: group.id, author_id: user.id, parent_id: epic_root.id, updated_at: updated_at)
  end

  let!(:epic2) do
    epics.create!(iid: 2, title: 'group-epic2', title_html: 'group-epic2',
                  group_id: group.id, author_id: user.id, parent_id: epic_root.id, updated_at: updated_at)
  end

  let!(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }

  let!(:issue1) do
    issues.create!(
      iid: 1, project_id: project.id, namespace_id: project.project_namespace_id,
      title: 'issue1', author_id: user.id, weight: 2, work_item_type_id: issue_type.id
    )
  end

  let!(:issue2) do
    issues.create!(
      iid: 1, project_id: project_root.id, namespace_id: project_root.project_namespace_id,
      title: 'issue1', author_id: user.id, weight: 1, work_item_type_id: issue_type.id
    )
  end

  let!(:issue3) do
    issues.create!(
      iid: 2, project_id: project_root.id, namespace_id: project_root.project_namespace_id,
      title: 'issue1', author_id: user.id, work_item_type_id: issue_type.id
    )
  end

  let!(:issue4) do
    issues.create!(
      iid: 3, project_id: project_root.id, namespace_id: project_root.project_namespace_id,
      title: 'issue1', author_id: user.id, weight: 4, state_id: 2, work_item_type_id: issue_type.id
    )
  end

  let!(:epic_issue1) { epic_issues.create!(issue_id: issue1.id, epic_id: epic_root.id) }
  let!(:epic_issue2) { epic_issues.create!(issue_id: issue2.id, epic_id: epic1.id) }
  let!(:epic_issue3) { epic_issues.create!(issue_id: issue3.id, epic_id: epic1.id) }
  let!(:epic_issue4) { epic_issues.create!(issue_id: issue4.id, epic_id: epic2.id) }

  let(:migration_attrs) do
    {
      start_id: epics.minimum(:id),
      end_id: epics.maximum(:id),
      batch_table: :epics,
      batch_column: :id,
      sub_batch_size: 1,
      pause_ms: 0,
      connection: ApplicationRecord.connection
    }
  end

  let(:migration) do
    described_class.new(**migration_attrs)
  end

  describe "#perform" do
    subject { migration.perform }

    it 'updates cache counts recursively from most nested subepics' do
      # for each level we call update_epics twice becase sub_batch_size is 1
      expect(migration).to receive(:update_epics).with(anything, level: 1).twice.and_call_original
      expect(migration).to receive(:update_epics).with(anything, level: 2).twice.and_call_original

      subject

      expect(epic1.reload).to have_attributes(
        total_opened_issue_weight: 1,
        total_closed_issue_weight: 0,
        total_opened_issue_count: 2,
        total_closed_issue_count: 0,
        updated_at: updated_at
      )
      expect(epic2.reload).to have_attributes(
        total_opened_issue_weight: 0,
        total_closed_issue_weight: 4,
        total_opened_issue_count: 0,
        total_closed_issue_count: 1,
        updated_at: updated_at
      )
      expect(epic_root.reload).to have_attributes(
        total_opened_issue_weight: 3,
        total_closed_issue_weight: 4,
        total_opened_issue_count: 3,
        total_closed_issue_count: 1,
        updated_at: updated_at
      )
    end

    context 'when there are too many nested levels' do
      before do
        stub_const("EE::#{described_class}::MAX_DEPTH", 1)
      end

      it 'aborts update when reaching max depth and logs error' do
        expect_next_instance_of(Gitlab::BackgroundMigration::Logger) do |instance|
          expect(instance).to receive(:error).with(message: 'too deep epic hierarchy', ids: [epic_root.id]).twice
        end

        subject

        expect(epic1.reload).to have_attributes(
          total_opened_issue_weight: 1,
          total_closed_issue_weight: 0,
          total_opened_issue_count: 2,
          total_closed_issue_count: 0,
          updated_at: updated_at
        )
        expect(epic2.reload).to have_attributes(
          total_opened_issue_weight: 0,
          total_closed_issue_weight: 4,
          total_opened_issue_count: 0,
          total_closed_issue_count: 1,
          updated_at: updated_at
        )
        expect(epic_root.reload).to have_attributes(
          total_opened_issue_weight: 0,
          total_closed_issue_weight: 0,
          total_opened_issue_count: 0,
          total_closed_issue_count: 0,
          updated_at: updated_at
        )
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
