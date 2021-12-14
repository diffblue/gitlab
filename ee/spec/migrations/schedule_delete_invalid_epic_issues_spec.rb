# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleDeleteInvalidEpicIssues do
  let(:migration) { described_class::MIGRATION }
  let(:users) { table(:users) }
  let(:namespaces) { table(:namespaces) }
  let(:epics) { table(:epics) }

  let(:user) { users.create!(name: 'test', email: 'test@example.com', projects_limit: 5) }
  let!(:group) { namespaces.create!(name: 'test 1', path: 'test1') }

  let!(:epic1) { epics.create!(iid: 1, title: 'test 1', title_html: 'test 1', group_id: group.id, author_id: user.id) }
  let!(:epic2) { epics.create!(iid: 2, title: 'test 2', title_html: 'test 2', group_id: group.id, author_id: user.id) }
  let!(:epic3) { epics.create!(iid: 3, title: 'test 3', title_html: 'test 3', group_id: group.id, author_id: user.id) }

  it 'correctly schedules background migrations' do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(migration).to be_scheduled_delayed_migration(2.minutes, epic1.id, epic2.id)
        expect(migration).to be_scheduled_delayed_migration(4.minutes, epic3.id, epic3.id)
      end
    end
  end
end
