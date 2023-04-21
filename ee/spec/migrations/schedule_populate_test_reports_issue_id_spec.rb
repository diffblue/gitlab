# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe SchedulePopulateTestReportsIssueId, feature_category: :requirements_management do
  let(:issues) { table(:issues) }
  let(:requirements) { table(:requirements) }
  let(:namespaces) { table(:namespaces) }
  let(:users) { table(:users) }
  let(:projects) { table(:projects) }
  let(:test_reports) { table(:requirements_management_test_reports) }

  let!(:group) { namespaces.create!(name: 'gitlab', path: 'gitlab-org') }
  let!(:project) { projects.create!(namespace_id: group.id, name: 'gitlab', path: 'gitlab') }

  let!(:user) { users.create!(email: 'author@example.com', notification_email: 'author@example.com', name: 'author', username: 'author', projects_limit: 10, state: 'active') }

  let!(:issue_1) { issues.create!(iid: 10, state_id: 1, project_id: project.id) }
  let!(:issue_2) { issues.create!(iid: 11, state_id: 2, project_id: project.id) }

  let!(:requirement_1) { requirements.create!(iid: 10, project_id: project.id, author_id: user.id, issue_id: issue_1.id, title: 'r 1', state: 1, created_at: 2.days.ago, updated_at: 1.day.ago) }
  let!(:requirement_2) { requirements.create!(iid: 11, project_id: project.id, author_id: user.id, issue_id: issue_2.id, title: 'r 1', state: 1, created_at: 2.days.ago, updated_at: 1.day.ago) }

  let!(:test_report_1) { test_reports.create!(requirement_id: requirement_1.id, state: 1) }
  let!(:test_report_2) { test_reports.create!(requirement_id: requirement_2.id, state: 1, issue_id: issue_1.id) }
  let!(:test_report_3) { test_reports.create!(requirement_id: requirement_2.id, state: 2) }
  let!(:test_report_4) { test_reports.create!(requirement_id: requirement_1.id, state: 2) }
  let!(:test_report_5) { test_reports.create!(requirement_id: requirement_1.id, state: 1) }

  let(:migration) { described_class::MIGRATION }

  before do
    Sidekiq::Worker.clear_all
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'schedules jobs correctly for test reports with null issue_id' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(migration).to be_scheduled_delayed_migration(120.seconds, test_report_1.id, test_report_3.id)
        expect(migration).to be_scheduled_delayed_migration(240.seconds, test_report_4.id, test_report_5.id)
        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
      end
    end
  end
end
