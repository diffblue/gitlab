# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesCheckProgress do
  context 'when there is MigrateApproverToApprovalRulesInBatch jobs' do
    it 'reschedules check' do
      allow(Gitlab::BackgroundMigration).to receive(:exists?).with('MigrateApproverToApprovalRulesInBatch').and_return(true)

      expect(BackgroundMigrationWorker).to receive(:perform_in).with(described_class::RESCHEDULE_DELAY, described_class.name)

      described_class.new.perform
    end
  end

  context 'when there is no more MigrateApproverToApprovalRulesInBatch jobs' do
    it 'enables feature' do
      allow(Gitlab::BackgroundMigration).to receive(:exists?).with('MigrateApproverToApprovalRulesInBatch').and_return(false)

      described_class.new.perform
    end
  end
end
