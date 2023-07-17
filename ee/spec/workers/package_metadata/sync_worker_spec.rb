# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncWorker, type: :worker, feature_category: :software_composition_analysis do
  describe '#perform' do
    subject(:perform!) { described_class.new.perform }

    it 'no longer calls sync service' do
      expect(PackageMetadata::SyncService).not_to receive(:execute)

      perform!
    end
  end
end
