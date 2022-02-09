# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe BackfillIntegrationsEnableSslVerification do
  let_it_be(:migration) { described_class::MIGRATION }
  let_it_be(:integrations) { table(:integrations) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)

    integrations.create!(id: 1, type: 'DroneCiService')
    integrations.create!(id: 2, type: 'BambooService')
    integrations.create!(id: 3, type: 'TeamcityService')
    integrations.create!(id: 4, type: 'DroneCiService')
    integrations.create!(id: 5, type: 'TeamcityService')
  end

  describe '#up' do
    it 'schedules background jobs for each batch of integrations', :freeze_time do
      Sidekiq::Testing.fake! do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(migration).to be_scheduled_delayed_migration(5.minutes, 1, 3)
        expect(migration).to be_scheduled_delayed_migration(10.minutes, 4, 5)
      end
    end
  end
end
