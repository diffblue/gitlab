# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositorySyncService, :geo do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:secondary) { create(:geo_node) }

  let(:registry) { create(:container_repository_registry, :sync_started) }
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

  context 'race condition when ContainerRepositoryUpdatedEvent was processed during a sync' do
    it 'reschedules the sync' do
      allow_any_instance_of(described_class).to receive(:registry).and_return(registry)

      expect(::Geo::ContainerRepositorySyncWorker).to receive(:perform_async)
      expect(registry).to receive(:finish_sync!).and_return(false)

      described_class.new(registry.container_repository).send(:mark_sync_as_successful)
    end
  end
end
