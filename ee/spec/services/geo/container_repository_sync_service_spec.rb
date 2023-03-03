# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositorySyncService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:secondary) { create(:geo_node) }

  let(:registry) { create(:geo_container_repository_registry) }
  let(:container_repository) { registry.container_repository }
  let(:lease_key) { "#{Geo::ContainerRepositorySyncService::LEASE_KEY}:#{container_repository.id}" }
  let(:lease_uuid) { 'uuid' }

  subject { described_class.new(container_repository) }

  before do
    stub_current_geo_node(secondary)
  end

  context 'lease handling' do
    before do
      stub_exclusive_lease(lease_key, lease_uuid)
    end

    it 'returns the lease when sync succeeds' do
      registry

      expect_to_cancel_exclusive_lease(lease_key, lease_uuid)

      allow_any_instance_of(Geo::ContainerRepositorySync).to receive(:execute)

      subject.execute
    end

    it 'returns the lease when sync fails' do
      allow_any_instance_of(Geo::ContainerRepositorySync).to receive(:execute)
        .and_raise(StandardError)

      expect_to_cancel_exclusive_lease(lease_key, lease_uuid)

      subject.execute
    end

    it 'skips syncing repositories if cannot obtain a lease' do
      stub_exclusive_lease_taken(lease_key)

      expect_any_instance_of(Geo::ContainerRepositorySync).not_to receive(:execute)

      subject.execute
    end
  end

  describe '#execute' do
    it 'fails registry record if there was exception' do
      allow_any_instance_of(Geo::ContainerRepositorySync)
        .to receive(:execute).and_raise 'Sync Error'

      described_class.new(registry.container_repository).execute

      expect(registry.reload.failed?).to be_truthy
    end

    it 'finishes registry record if there was no exception' do
      expect_any_instance_of(Geo::ContainerRepositorySync)
        .to receive(:execute)

      described_class.new(registry.container_repository).execute

      expect(registry.reload.synced?).to be_truthy
    end

    it 'finishes registry record if there was no exception and registy does not exist' do
      expect_any_instance_of(Geo::ContainerRepositorySync)
        .to receive(:execute)

      described_class.new(container_repository).execute

      registry = Geo::ContainerRepositoryRegistry.find_by(container_repository_id: container_repository.id)

      expect(registry.synced?).to be_truthy
    end
  end

  context 'reschedules sync due to race condition instead of waiting for backfill' do
    describe '#mark_sync_as_successful' do
      context 'when UpdatedEvent was processed during a sync' do
        it 'reschedules the sync' do
          expect(::Geo::ContainerRepositorySyncWorker)
            .to receive(:perform_async)
            .with(container_repository.id)
            .once

          expect_any_instance_of(registry.class)
            .to receive(:synced!)
            .once
            .and_call_original

          registry.pending!

          subject.send(:mark_sync_as_successful)
        end
      end
    end
  end
end
