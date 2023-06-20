# frozen_string_literal: true

require 'spec_helper'

# rubocop:disable RSpec/FactoriesInMigrationSpecs
RSpec.describe Gitlab::BackgroundMigration::MigrateApproverToApprovalRulesInBatch do
  context 'when there is no more MigrateApproverToApprovalRules jobs' do
    let(:job) { double(:job) }
    let(:project) { create(:project) }

    it 'migrates individual target' do
      allow(Gitlab::BackgroundMigration::MigrateApproverToApprovalRules).to receive(:new).and_return(job)

      merge_requests = create_list(:merge_request, 3, :skip_diff_creation)

      expect(job).to receive(:perform).exactly(3).times

      described_class.new.perform(merge_requests.first.id, merge_requests.last.id)
    end
  end
end
# rubocop:enable RSpec/FactoriesInMigrationSpecs
