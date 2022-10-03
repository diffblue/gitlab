# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::ContainerRepositorySyncDispatchWorker, :geo, :use_sql_query_cache_for_tracking_db do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  before do
    stub_feature_flags(geo_container_repository_replication: false)

    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)
    stub_registry_replication_config(enabled: true)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:over_time?).and_return(false)
    end

    allow(Geo::ContainerRepositorySyncWorker).to receive(:with_status).and_return(Geo::ContainerRepositorySyncWorker)
  end

  it 'does not schedule anything when tracking database is not configured' do
    create(:container_repository)

    allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

    expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

    subject.perform

    # We need to unstub here or the DatabaseCleaner will have issues since it
    # will appear as though the tracking DB were not available
    allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
  end

  it 'does not schedule anything when node is disabled' do
    secondary.update!(enabled: false)
    create(:container_repository)

    expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

    subject.perform
  end

  it 'does not schedule anything when ff is enabled' do
    stub_feature_flags(geo_container_repository_replication: true)

    create(:container_repository_registry)

    expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:log_info).with('Container Registry replication is handled by Geo SSF framework')
    end

    subject.perform
  end

  it 'does not schedule anything when registry replication is disabled' do
    stub_registry_replication_config(enabled: false)
    create(:container_repository)

    expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:log_info).with('Container Registry replication is not enabled')
    end
  end

  it 'performs Geo::ContainerRepositorySyncWorker' do
    registry = create(:container_repository_registry)

    expect(Geo::ContainerRepositorySyncWorker).to receive(:perform_async).with(registry.container_repository_id)

    subject.perform
  end

  it 'performs Geo::ContainerRepositorySyncWorker for failed syncs' do
    registry = create(:container_repository_registry, :sync_failed)

    expect(Geo::ContainerRepositorySyncWorker).to receive(:perform_async)
      .with(registry.container_repository_id).once.and_return(spy)

    subject.perform
  end

  it 'does not perform Geo::ContainerRepositorySyncWorker for synced repositories' do
    create(:container_repository_registry, :synced)

    expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async)

    subject.perform
  end

  context 'with a failed sync' do
    it 'does not stall backfill' do
      failed_registry = create(:container_repository_registry, :sync_failed)
      unsynced_registry = create(:container_repository_registry)

      stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 1)

      expect(Geo::ContainerRepositorySyncWorker).not_to receive(:perform_async).with(failed_registry.container_repository_id)
      expect(Geo::ContainerRepositorySyncWorker).to receive(:perform_async).with(unsynced_registry.container_repository_id)

      subject.perform
    end

    it 'does not retry failed files when retry_at is tomorrow' do
      failed_registry = create(:container_repository_registry, :sync_failed, retry_at: Date.tomorrow)

      expect(Geo::ContainerRepositorySyncWorker)
        .not_to receive(:perform_async).with( failed_registry.container_repository_id)

      subject.perform
    end

    it 'retries failed files when retry_at is in the past' do
      failed_registry = create(:container_repository_registry, :sync_failed, retry_at: Date.yesterday)

      expect(Geo::ContainerRepositorySyncWorker)
        .to receive(:perform_async).with(failed_registry.container_repository_id)

      subject.perform
    end
  end
end
