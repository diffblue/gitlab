# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignRepositoryShardSyncWorker, :geo, :clean_gitlab_redis_cache, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }

    let(:shard_name) { Gitlab.config.repositories.storages.each_key.first }

    before do
      stub_current_geo_node(secondary)
      stub_exclusive_lease(renew: true)

      Gitlab::ShardHealthCache.update([shard_name])

      create(:design, project: project_1)
      create(:design, project: project_2)

      allow(Geo::DesignRepositorySyncWorker).to receive(:with_status).and_return(Geo::DesignRepositorySyncWorker)
    end

    it 'does not perform Geo::DesignRepositorySyncWorker when shard becomes unhealthy' do
      Gitlab::ShardHealthCache.update([])

      log_data = { message: "Skipped scheduling syncs due to unhealthy shard", shard_name: shard_name }
      expect(Gitlab::Geo::Logger).to receive(:error).with(a_hash_including(log_data))
      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::DesignRepositorySyncWorker when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not perform Geo::ProjectSyncWorker when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::DesignRepositorySyncWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::DesignRepositorySyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'performs Geo::DesignRepositorySyncWorker for each registry' do
      create(:geo_design_registry, project: project_1)
      create(:geo_design_registry, project: project_2)

      expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'performs Geo::DesignRepositorySyncWorker for designs where last attempt to sync failed' do
      create(:geo_design_registry, :sync_failed, project: project_1)
      create(:geo_design_registry, :synced, project: project_2)

      expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async).once.and_return(spy)

      subject.perform(shard_name)
    end

    it 'performs Geo::DesignRepositorySyncWorker for designs updated recently' do
      create(:geo_design_registry, project: project_1)
      create(:geo_design_registry, :synced, project: project_2)
      create(:geo_design_registry)

      expect(Geo::DesignRepositorySyncWorker).to receive(:perform_async).twice.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not schedule a job twice for the same project' do
      create(:geo_design_registry, project: project_1)
      create(:geo_design_registry, project: project_2)

      scheduled_jobs = [
        { job_id: 1, project_id: project_2.id },
        { job_id: 2, project_id: project_1.id }
      ]

      is_expected.to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    context 'with multiple shards' do
      it 'uses two loops to schedule jobs', :sidekiq_inline do
        expect(subject).to receive(:schedule_jobs).twice.and_call_original

        Gitlab::ShardHealthCache.update([shard_name, 'shard2', 'shard3', 'shard4', 'shard5'])
        secondary.update!(repos_max_capacity: 5)

        create(:geo_design_registry, project: project_1)
        create(:geo_design_registry, project: project_2)

        subject.perform(shard_name)
      end
    end
  end
end
