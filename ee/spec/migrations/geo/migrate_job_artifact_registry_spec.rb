# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe MigrateJobArtifactRegistry do
  let(:migration_name) { 'MigrateJobArtifactRegistryToSsf' }

  let(:registry) { table(:job_artifact_registry) }

  let!(:registry1) { registry.create!(artifact_id: 1, success: true, state: 0) }
  let!(:registry2) { registry.create!(artifact_id: 2, success: true, state: 0) }
  let!(:registry3) { registry.create!(artifact_id: 3, success: true, state: 0) }
  let!(:registry4) { registry.create!(artifact_id: 4, success: true, state: 0) }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(described_class::MIGRATION).to be_scheduled_migration_with_multiple_args(registry1.id, registry2.id)
        expect(described_class::MIGRATION).to be_scheduled_migration_with_multiple_args(registry3.id, registry4.id)
      end
    end
  end
end
