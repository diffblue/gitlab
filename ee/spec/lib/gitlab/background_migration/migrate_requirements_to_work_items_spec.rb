# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateRequirementsToWorkItems,
  :migration, schema: 20220505174658, feature_category: :team_planning do
  let!(:issue_base_type_enum) { 0 }
  let!(:issue_type_id) { table(:work_item_types).find_by(base_type: issue_base_type_enum).id }

  let(:issues) { table(:issues) }
  let(:requirements) { table(:requirements) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:internal_ids) { table(:internal_ids) }

  let(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let(:project_namespace_1) { namespaces.create!(name: 'project-namespace1', path: 'project-namespace1', type: 'Project', parent_id: group.id) }
  let(:project_namespace_2) { namespaces.create!(name: 'project-namespace2', path: 'project-namespace2', type: 'Project', parent_id: group.id) }
  let(:project) { projects.create!(namespace_id: group.id, name: 'gitlab', path: 'gitlab', project_namespace_id: project_namespace_1.id) }
  let(:project2) { projects.create!(namespace_id: group.id, name: 'gitlab2', path: 'gitlab2', project_namespace_id: project_namespace_2.id) }
  let(:user1) { users.create!(email: 'author@example.com', notification_email: 'author@example.com', name: 'author', username: 'author', projects_limit: 10, state: 'active') }
  let(:user2) { users.create!(email: 'author2@example.com', notification_email: 'author2@example.com', name: 'author2', username: 'author2', projects_limit: 10, state: 'active') }
  let(:issue) { issues.create!(iid: 5, state_id: 1, project_id: project2.id, work_item_type_id: issue_type_id) }

  let!(:requirement_1) { create_requirement(iid: 1, project_id: project.id, author_id: user1.id, title: 'r 1', state: 1, created_at: 2.days.ago, updated_at: 1.day.ago) }

  # Create one requirement with issue_id present, to make sure a job won't be scheduled for it
  let!(:requirement_2) { requirements.create!(iid: 2, project_id: project2.id, author_id: user1.id, issue_id: issue.id, title: 'r 2', state: 1, created_at: Time.current, updated_at: Time.current) }

  let!(:requirement_3) { requirements.create!(iid: 3, project_id: project.id, title: 'r 3', state: 1, created_at: 3.days.ago, updated_at: 2.days.ago) }
  let!(:requirement_4) { requirements.create!(iid: 99, project_id: project2.id, author_id: user1.id, title: 'r 4', state: 2, created_at: 1.hour.ago, updated_at: Time.current) }
  let!(:requirement_5) { requirements.create!(iid: 5, project_id: project2.id, author_id: user2.id, title: 'r 5', state: 1, created_at: 2.hours.ago, updated_at: Time.current) }

  let(:migration) { described_class::MIGRATION }

  let(:now) { Time.now.utc.to_s }

  around do |example|
    freeze_time { example.run }
  end

  subject(:migrate_requirements) do
    described_class.new.perform(requirement_1.id, requirement_5.id)
  end

  it 'creates work items for not synced requirements' do
    expect { migrate_requirements }.to change { issues.count }.by(4)
  end

  it 'creates requirement work items with correct attributes' do
    migrate_requirements

    [requirement_1, requirement_3, requirement_4, requirement_5].each do |requirement|
      issue = issues.find(requirement.reload.issue_id)

      expect(issue.issue_type).to eq(3) # requirement work item type
      expect(issue.title).to eq(requirement.title)
      expect(issue.description).to eq(requirement.description)
      expect(issue.project_id).to eq(requirement.project_id)
      expect(issue.state_id).to eq(requirement.state)
      expect(issue.author_id).to eq(requirement.author_id)
      expect(issue.iid).to be_present
      expect(issue.created_at).to eq(requirement.created_at)
      expect(issue.updated_at.to_s).to eq(now) # issues updated_at column do not persist timezone
    end
  end

  it 'populates iid correctly' do
    migrate_requirements

    # Projects without issues
    expect(issues.find(requirement_1.reload.issue_id).iid).to eq(1)
    expect(issues.find(requirement_3.reload.issue_id).iid).to eq(2)
    # Project that already has one issue with iid = 5
    expect(issues.find(requirement_4.reload.issue_id).iid).to eq(6)
    expect(issues.find(requirement_5.reload.issue_id).iid).to eq(7)
  end

  it 'tracks iid greatest value' do
    internal_ids.create!(project_id: issue.project_id, usage: 0, last_value: issue.iid)

    migrate_requirements

    expect(internal_ids.count).to eq(2) # Creates record for project when there is not one
    expect(internal_ids.find_by_project_id(project.id).last_value).to eq(2)
    expect(internal_ids.find_by_project_id(project2.id).last_value).to eq(7)
  end

  def create_requirement(**args)
    requirements.create!(
      iid: args[:iid],
      project_id: args[:project_id],
      issue_id: args[:issue_id],
      title: args[:title],
      state: args[:state],
      created_at: args[:created_at],
      updated_at: args[:updated_at],
      author_id: args[:author_id])
  end
end
