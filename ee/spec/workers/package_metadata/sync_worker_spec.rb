# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PackageMetadata::SyncWorker, type: :worker, feature_category: :license_compliance do
  include_examples 'an idempotent worker' do
    before do
      allow(PackageMetadata::SyncService).to receive(:execute)
    end

    subject do
      perform_multiple([], worker: described_class.new)
    end
  end

  describe '#perform' do
    subject(:perform) { described_class.new.perform }

    context 'with feature flag enabled' do
      it 'calls the sync service to do the work' do
        expect(PackageMetadata::SyncService).to receive(:execute)
        perform
      end
    end

    context 'with feature flag disabled' do
      before do
        stub_feature_flags(package_metadata_synchronization: false)
      end

      it 'does not call the sync service to do the work' do
        expect(PackageMetadata::SyncService).not_to receive(:execute)
        perform
      end
    end
  end
end
