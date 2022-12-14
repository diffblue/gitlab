# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleRequirementsMigration, feature_category: :requirements_management do
  let(:issues) { table(:issues) }
  let(:requirements) { table(:requirements) }
  let(:namespaces) { table(:namespaces) }
  let(:projects) { table(:projects) }
  let(:users) { table(:users) }
  let!(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let!(:project) { projects.create!(namespace_id: group.id, name: 'gitlab', path: 'gitlab') }
  let(:migration) { described_class::MIGRATION }
  let!(:issue) { issues.create!(state_id: 1) }

  let!(:author) { users.create!(email: 'author@example.com', notification_email: 'author@example.com', name: 'author', username: 'author', projects_limit: 10, state: 'active') }

  let!(:requirement_1) { requirements.create!(iid: 1, project_id: project.id, title: 'r 1', state: 1, created_at: Time.now, updated_at: Time.now, author_id: author.id) }

  # Already in sync
  let!(:requirement_2) { requirements.create!(iid: 2, project_id: project.id, issue_id: issue.id, title: 'r 2', state: 1, created_at: Time.now, updated_at: Time.now, author_id: author.id) }

  let!(:requirement_3) { requirements.create!(iid: 3, project_id: project.id, title: 'r 3', state: 1, created_at: Time.now, updated_at: Time.now, author_id: author.id) }
  let!(:requirement_4) { requirements.create!(iid: 99, project_id: project.id, title: 'r 4', state: 2, created_at: Time.now, updated_at: Time.now, author_id: author.id) }
  let!(:requirement_5) { requirements.create!(iid: 5, project_id: project.id, title: 'r 5', state: 1, created_at: Time.now, updated_at: Time.now, author_id: author.id) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  context 'scheduling migrations' do
    before do
      Sidekiq::Worker.clear_all
    end

    it 'schedules jobs for all requirements without issues in sync' do
      Sidekiq::Testing.fake! do
        freeze_time do
          migrate!

          expect(migration).to be_scheduled_delayed_migration(120.seconds, requirement_1.id, requirement_3.id)
          expect(migration).to be_scheduled_delayed_migration(240.seconds, requirement_4.id, requirement_5.id)
          expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        end
      end
    end
  end
end
