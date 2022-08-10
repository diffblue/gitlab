# frozen_string_literal: true

require 'spec_helper'

# rubocop: disable Layout/LineLength
# rubocop: disable RSpec/ScatteredLet
# rubocop: disable RSpec/MultipleMemoizedHelpers
RSpec.describe Gitlab::BackgroundMigration::BatchingStrategies::InvalidGroupMembersBatchingStrategy, '#next_batch' do
  let(:batching_strategy) { described_class.new(connection: ApplicationRecord.connection) }
  let(:namespaces_table) { table(:namespaces) }
  let(:projects_table) { table(:projects) }
  let(:users_table) { table(:users) }
  let(:members_table) { table(:members) }

  let(:user1) { users_table.create!(name: 'user1', email: 'user1@example.com', projects_limit: 5) }
  let(:user2) { users_table.create!(name: 'user2', email: 'user2@example.com', projects_limit: 5) }
  let(:user3) { users_table.create!(name: 'user3', email: 'user3@example.com', projects_limit: 5) }
  let(:user4) { users_table.create!(name: 'user4', email: 'user4@example.com', projects_limit: 5) }
  let(:user5) { users_table.create!(name: 'user5', email: 'user5@example.com', projects_limit: 5) }
  let(:user6) { users_table.create!(name: 'user6', email: 'user6@example.com', projects_limit: 5) }
  let(:user7) { users_table.create!(name: 'user7', email: 'user7@example.com', projects_limit: 5) }
  let(:user8) { users_table.create!(name: 'user8', email: 'user8@example.com', projects_limit: 5) }

  let!(:group1) do
    namespaces_table.create!(name: 'group1', type: 'Group', path: 'group1')
  end

  let!(:group2) do
    namespaces_table.create!(name: 'group2', type: 'Group', path: 'group2')
  end

  let!(:project_namespace1) do
    namespaces_table.create!(name: 'myproject1', path: 'myproject1', type: 'Project', parent_id: group1.id)
  end

  let!(:project1) do
    projects_table.create!(name: 'myproject1', path: 'myproject1', namespace_id: group1.id, project_namespace_id: project_namespace1.id)
  end

  # mix of Group and Project members
  let!(:member1) { create_valid_group_member(id: 1, user_id: user1.id, group_id: group1.id) }
  let!(:member2) { create_invalid_group_member(id: 2, user_id: user2.id) }
  let!(:member3) { create_invalid_project_member(id: 3, user_id: user3.id) }
  let!(:member4) { create_valid_group_member(id: 4, user_id: user4.id, group_id: group1.id) }
  let!(:member5) { create_valid_group_member(id: 5, user_id: user5.id, group_id: group1.id) }
  let!(:member6) { create_valid_project_member(id: 6, user_id: user6.id, project_id: project1.id, project_namespace_id: project_namespace1.id) }
  let!(:member7) { create_invalid_group_member(id: 7, user_id: user7.id) }
  let!(:member8) { create_invalid_project_member(id: 8, user_id: user8.id) }
  let!(:member9) { create_invalid_group_member(id: 9, user_id: user1.id) }
  let!(:member10) { create_invalid_group_member(id: 10, user_id: user1.id) }
  let!(:member11) { create_invalid_group_member(id: 11, user_id: user1.id) }
  let!(:member12) { create_invalid_group_member(id: 12, user_id: user1.id) }

  it { expect(described_class).to be < Gitlab::BackgroundMigration::BatchingStrategies::PrimaryKeyBatchingStrategy }

  context 'when starting on the first batch' do
    it 'returns the bounds of the next batch (counts 3 invalid group members)' do
      batch_bounds = batching_strategy.next_batch(
        :members,
        :id,
        batch_min_value: member1.id,
        batch_size: 3,
        job_arguments: []
      )

      # first 3 group members, filtered out project members
      expect(batch_bounds).to match_array([member1.id, member4.id])
    end
  end

  context 'when additional batches remain' do
    it 'returns the bounds of the next batch' do
      batch_bounds = batching_strategy.next_batch(
        :members,
        :id,
        batch_min_value: member10.id,
        batch_size: 3,
        job_arguments: []
      )

      expect(batch_bounds).to match_array([member10.id, member12.id])
    end
  end

  context 'when no additional batches remain' do
    it 'returns nil' do
      batch_bounds = batching_strategy.next_batch(:members,
                                                  :id,
                                                  batch_min_value: member12.id + 1,
                                                  batch_size: 1, job_arguments: [])

      expect(batch_bounds).to be_nil
    end
  end

  def create_invalid_group_member(id:, user_id:)
    members_table.create!(id: id, user_id: user_id, source_id: non_existing_record_id, access_level: Gitlab::Access::MAINTAINER,
                          type: "GroupMember", source_type: "Namespace", notification_level: 3, member_namespace_id: nil)
  end

  def create_valid_group_member(id:, user_id:, group_id:)
    members_table.create!(id: id, user_id: user_id, source_id: group_id, access_level: Gitlab::Access::MAINTAINER,
                          type: "GroupMember", source_type: "Namespace", member_namespace_id: group_id, notification_level: 3)
  end

  def create_invalid_project_member(id:, user_id:)
    members_table.create!(id: id, user_id: user_id, source_id: non_existing_record_id, access_level: Gitlab::Access::MAINTAINER,
                          type: "ProjectMember", source_type: "Project", notification_level: 3, member_namespace_id: nil)
  end

  def create_valid_project_member(id:, user_id:, project_id:, project_namespace_id:)
    members_table.create!(id: id, user_id: user_id, source_id: project_id, access_level: Gitlab::Access::MAINTAINER,
                          type: "ProjectMember", source_type: "Project", member_namespace_id: project_namespace_id, notification_level: 3)
  end
  # rubocop: enable RSpec/MultipleMemoizedHelpers
  # rubocop: enable Layout/LineLength
  # rubocop: enable RSpec/ScatteredLet
end
