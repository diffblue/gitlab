# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe ScheduleTraceExpiryRemoval, :suppress_gitlab_schemas_validate_connection, feature_category: :build_artifacts do
  let(:scheduling_migration) { described_class.new }
  let(:background_migration) { described_class::MIGRATION }
  let(:matching_row_attrs)   { { created_at: Date.new(2020, 06, 20), expire_at: Date.new(2022, 01, 22), project_id: 1, file_type: 3 } }

  before do
    Sidekiq::Worker.clear_all
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    table(:namespaces).create!(id: 1, name: 'the-namespace', path: 'the-path')
    table(:projects).create!(id: 1, name: 'the-project', namespace_id: 1)

    1.upto(10) do |n|
      table(:ci_builds).create!(id: n, allow_failure: false)
      table(:ci_job_artifacts).create!(id: n, job_id: n, **matching_row_attrs)
    end
  end

  context 'on gitlab.com', :saas do
    describe '#up' do
      it 'schedules batches of the correct size at 2 minute intervals' do
        Sidekiq::Testing.fake! do
          freeze_time do
            migrate!

            expect(background_migration).to be_scheduled_delayed_migration(240.seconds, 1, 2)
            expect(background_migration).to be_scheduled_delayed_migration(480.seconds, 3, 4)
            expect(background_migration).to be_scheduled_delayed_migration(720.seconds, 5, 6)
            expect(background_migration).to be_scheduled_delayed_migration(960.seconds, 7, 8)
            expect(background_migration).to be_scheduled_delayed_migration(1200.seconds, 9, 10)
            expect(BackgroundMigrationWorker.jobs.size).to eq(5)
          end
        end
      end
    end
  end

  context 'on self-hosted instances' do
    describe '#up' do
      it 'does nothing' do
        Sidekiq::Testing.fake! do
          migrate!

          expect(BackgroundMigrationWorker.jobs.size).to eq(0)
        end
      end
    end
  end
end
