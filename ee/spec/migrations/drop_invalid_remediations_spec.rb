# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe DropInvalidRemediations, :migration, feature_category: :vulnerability_management do
  let(:migration_name) { 'DropInvalidRemediations' }

  let(:remediations) { table(:vulnerability_findings_remediations) }

  let!(:old_remediation1) { remediations.create!( created_at: '1/1/2021') }
  let!(:remediation1) { remediations.create! }
  let!(:remediation2) { remediations.create! }
  let!(:remediation3) { remediations.create! }
  let!(:remediation4) { remediations.create! }

  before do
    stub_const("#{described_class.name}::BATCH_SIZE", 2)
  end

  it 'correctly schedules background migrations' do
    Sidekiq::Testing.fake! do
      freeze_time do
        migrate!

        expect(BackgroundMigrationWorker.jobs.size).to eq(2)
        expect(described_class::MIGRATION_NAME).to be_scheduled_migration_with_multiple_args(remediation1.id, remediation2.id)
        expect(described_class::MIGRATION_NAME).to be_scheduled_migration_with_multiple_args(remediation3.id, remediation4.id)
      end
    end
  end
end
