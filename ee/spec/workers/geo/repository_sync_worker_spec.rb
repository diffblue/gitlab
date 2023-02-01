# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositorySyncWorker, :geo, :clean_gitlab_redis_cache do
  include ::EE::GeoHelpers

  let!(:primary) { create(:geo_node, :primary) }
  let!(:secondary) { create(:geo_node) }
  let!(:synced_group) { create(:group) }
  let!(:project_in_synced_group) { create(:project, group: synced_group) }
  let!(:unsynced_project) { create(:project) }
  let(:healthy_shard_name) { project_in_synced_group.repository.storage }
  let(:design_worker) { Geo::DesignRepositoryShardSyncWorker }
  let(:repository_worker) { Geo::RepositoryShardSyncWorker }

  before do
    stub_current_geo_node(secondary)
  end

  around do |example|
    Sidekiq::Testing.inline! { example.run }
  end

  context 'additional shards' do
    it 'skips backfill for repositories on other shards' do
      create(:project, :broken_storage, group: synced_group)
      unhealthy_dirty = create(:project, :broken_storage, group: synced_group)
      create(:geo_project_registry, :synced, :repository_dirty, project: unhealthy_dirty)

      allow(Gitlab::GitalyClient).to receive(:call) do
        raise GRPC::Unavailable, 'No Gitaly available'
      end

      expect(repository_worker).not_to receive(:perform_async).with('broken')
      expect(design_worker).not_to receive(:perform_async).with('broken')

      subject.perform
    end

    it 'skips backfill for projects on shards excluded by selective sync' do
      secondary.update!(selective_sync_type: 'shards', selective_sync_shards: [healthy_shard_name])

      # Report both shards as healthy
      expect(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness)
        .and_return([result(true, healthy_shard_name), result(true, 'broken')])

      expect(repository_worker).to receive(:perform_async).with('default')
      expect(design_worker).to receive(:perform_async).with('default')
      expect(repository_worker).not_to receive(:perform_async).with('broken')
      expect(design_worker).not_to receive(:perform_async).with('broken')

      subject.perform
    end

    it 'skips backfill for projects on missing shards' do
      missing_not_synced = create(:project, group: synced_group)
      missing_not_synced.update_column(:repository_storage, 'unknown')
      missing_dirty = create(:project, group: synced_group)
      missing_dirty.update_column(:repository_storage, 'unknown')

      create(:geo_project_registry, :synced, :repository_dirty, project: missing_dirty)

      # hide the 'broken' storage for this spec
      stub_storage_settings({})

      expect(repository_worker).to receive(:perform_async).with(project_in_synced_group.repository.storage)
      expect(design_worker).to receive(:perform_async).with(project_in_synced_group.repository.storage)
      expect(repository_worker).not_to receive(:perform_async).with('unknown')
      expect(design_worker).not_to receive(:perform_async).with('unknown')

      subject.perform
    end

    it 'skips backfill for projects with downed Gitaly server' do
      create(:project, :broken_storage, group: synced_group)
      unhealthy_dirty = create(:project, :broken_storage, group: synced_group)

      create(:geo_project_registry, :synced, :repository_dirty, project: unhealthy_dirty)

      # Report only one healthy shard
      expect(Gitlab::HealthChecks::GitalyCheck).to receive(:readiness)
        .and_return([result(true, healthy_shard_name), result(false, 'broken')])

      expect(repository_worker).to receive(:perform_async).with(healthy_shard_name)
      expect(design_worker).to receive(:perform_async).with(healthy_shard_name)
      expect(repository_worker).not_to receive(:perform_async).with('broken')
      expect(design_worker).not_to receive(:perform_async).with('broken')

      subject.perform
    end
  end

  def result(success, shard)
    Gitlab::HealthChecks::Result.new('gitaly_check', success, nil, { shard: shard })
  end
end
