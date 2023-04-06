# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryShardSyncWorker, :geo, :clean_gitlab_redis_cache, :use_sql_query_cache_for_tracking_db, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let_it_be(:primary) { create(:geo_node, :primary) }
    let_it_be(:secondary) { create(:geo_node) }

    let!(:project_1) { create(:project) }
    let!(:project_2) { create(:project) }
    let(:shard_name) { Gitlab.config.repositories.storages.each_key.first }

    before do
      stub_current_geo_node(secondary)
      stub_exclusive_lease(renew: true)

      Gitlab::ShardHealthCache.update([shard_name])

      allow(Geo::ProjectSyncWorker).to receive(:with_status).and_return(Geo::ProjectSyncWorker)
    end

    it 'does not perform Geo::ProjectSyncWorker when shard becomes unhealthy' do
      Gitlab::ShardHealthCache.update([])

      log_data = { message: "Skipped scheduling syncs due to unhealthy shard", shard_name: shard_name }
      expect(Gitlab::Geo::Logger).to receive(:error).with(a_hash_including(log_data))
      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::ProjectSyncWorker when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not perform Geo::ProjectSyncWorker when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::ProjectSyncWorker when node is disabled' do
      allow_any_instance_of(GeoNode).to receive(:enabled?) { false }

      expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    context 'number of scheduled jobs exceeds capacity' do
      it 'schedules 0 jobs' do
        is_expected.to receive(:scheduled_job_ids).and_return((1..1000).to_a).at_least(:once)
        is_expected.not_to receive(:schedule_job)

        Sidekiq::Testing.inline! { subject.perform(shard_name) }
      end
    end

    it 'performs Geo::ProjectSyncWorker for each registry' do
      create(:geo_project_registry, project: project_2)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).once.and_return(spy)

      subject.perform(shard_name)
    end

    it 'performs Geo::ProjectSyncWorker for projects where last attempt to sync failed' do
      create(:geo_project_registry, :sync_failed, project: project_1)
      create(:geo_project_registry, :synced, project: project_2)

      expect(Geo::ProjectSyncWorker).to receive(:perform_async).once.and_return(spy)

      subject.perform(shard_name)
    end

    it 'does not schedule a job twice for the same project' do
      create(:geo_project_registry, project: project_2)
      create(:geo_project_registry, project: project_1)

      scheduled_jobs = [
        { job_id: 1, project_id: project_2.id },
        { job_id: 2, project_id: project_1.id }
      ]

      is_expected.to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    context 'backoff time' do
      let(:cache_key) { "#{described_class.name.underscore}:shard:#{shard_name}:skip" }

      before do
        allow(Rails.cache).to receive(:read).and_call_original
        allow(Rails.cache).to receive(:write).and_call_original
      end

      it 'sets the back off time when there are no pending items' do
        create(:geo_project_registry, :synced, project: project_1)
        create(:geo_project_registry, :synced, project: project_2)

        expect(Rails.cache).to receive(:write).with(cache_key, true, expires_in: 300.seconds).once

        subject.perform(shard_name)
      end

      it 'does not perform Geo::ProjectSyncWorker when the backoff time is set' do
        expect(Rails.cache).to receive(:read).with(cache_key).and_return(true)

        expect(Geo::ProjectSyncWorker).not_to receive(:perform_async)

        subject.perform(shard_name)
      end
    end

    context 'repositories that have never been updated' do
      let!(:project_list) { create_list(:project, 4, last_repository_updated_at: 2.hours.ago) }
      let!(:abandoned_project) { create(:project) }

      before do
        # Project sync failed but never received an update
        create(:geo_project_registry, :repository_sync_failed, project: abandoned_project)
        abandoned_project.update_column(:last_repository_updated_at, 1.year.ago)

        # Neither of these are needed for this spec
        project_2.destroy!
        project_1.destroy!

        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:db_retrieve_batch_size).and_return(2) # Must be >1 because of the Geo::BaseSchedulerWorker#interleave
        end

        secondary.update!(repos_max_capacity: 3) # Must be more than db_retrieve_batch_size

        project_list.each do |project|
          create(:geo_project_registry, project: project)

          allow(Geo::ProjectSyncWorker)
            .to receive(:perform_async)
              .with(project.id, anything)
              .and_call_original
        end

        allow_next_instance_of(Geo::ProjectRegistry) do |instance|
          allow(instance).to receive(:wiki_sync_due?).and_return(false)
        end

        allow_next_instance_of(Geo::RepositorySyncService) do |instance|
          allow(instance).to receive(:expire_repository_caches)
        end
      end

      it 'tries to sync project where last attempt to sync failed' do
        expect(Geo::ProjectSyncWorker)
          .to receive(:perform_async)
            .with(abandoned_project.id, anything)
            .at_least(:once)
            .and_return(spy)

        3.times do
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end
    end

    context 'when all repositories fail' do
      let!(:project_list) { create_list(:project, 4, :random_last_repository_updated_at) }

      before do
        # Neither of these are needed for this spec
        project_2.destroy!
        project_1.destroy!

        allow_next_instance_of(described_class) do |instance|
          allow(instance).to receive(:db_retrieve_batch_size).and_return(2) # Must be >1 because of the Geo::BaseSchedulerWorker#interleave
        end
        secondary.update!(repos_max_capacity: 3) # Must be more than db_retrieve_batch_size

        allow_next_instance_of(Project) do |instance|
          allow(instance).to receive(:ensure_repository).and_raise(Gitlab::Shell::Error.new('foo'))
        end

        allow_next_instance_of(Geo::ProjectRegistry) do |instance|
          allow(instance).to receive(:wiki_sync_due?).and_return(false)
        end

        allow_next_instance_of(Geo::RepositorySyncService) do |instance|
          allow(instance).to receive(:expire_repository_caches)
        end

        allow_next_instance_of(Geo::ProjectHousekeepingService) do |instance|
          allow(instance).to receive(:do_housekeeping)
        end
      end

      it 'tries to sync every project' do
        project_list.each do |project|
          create(:geo_project_registry, project: project)

          expect(Geo::ProjectSyncWorker)
            .to receive(:perform_async)
              .with(project.id, anything)
              .at_least(:once)
              .and_call_original
        end

        3.times do
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end

      context 'projects that require resync' do
        context 'when project repository is dirty' do
          it 'does not sync repositories' do
            create(:geo_project_registry, :synced, :repository_dirty, project: project_2)
            create(:geo_project_registry, :synced, :repository_dirty, project: project_1)

            expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project_2.id, sync_repository: true, sync_wiki: false)
            expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project_1.id, sync_repository: true, sync_wiki: false)

            subject.perform(shard_name)
          end
        end

        context 'when project wiki is dirty' do
          it 'does not syn wikis' do
            create(:geo_project_registry, :synced, :wiki_dirty, project: project_2)
            create(:geo_project_registry, :synced, :wiki_dirty, project: project_1)

            expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project_2.id, sync_repository: false, sync_wiki: true)
            expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project_1.id, sync_repository: false, sync_wiki: true)

            subject.perform(shard_name)
          end
        end
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      it 'performs Geo::ProjectSyncWorker for synced projects/wikis updated recently' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_1)
        create(:geo_project_registry, :synced, project: project_2)
        create(:geo_project_registry, :synced, :wiki_dirty)

        expect(Geo::ProjectSyncWorker).to receive(:perform_async).twice.and_return(spy)

        subject.perform(shard_name)
      end

      context 'with multiple shards' do
        it 'uses two loops to schedule jobs', :sidekiq_might_not_need_inline do
          create(:geo_project_registry, project: project_2)
          create(:geo_project_registry, project: project_1)

          Gitlab::ShardHealthCache.update([shard_name, 'shard2', 'shard3', 'shard4', 'shard5'])
          secondary.update!(repos_max_capacity: 5)

          expect(subject).to receive(:schedule_jobs).twice.and_call_original

          subject.perform(shard_name)
        end

        it 'skips backfill for projects on unhealthy shards' do
          project_unhealthy_shard = create_project_on_shard('unknown')

          create(:geo_project_registry, project: project_1)
          create(:geo_project_registry, project: project_unhealthy_shard)

          expect(Geo::ProjectSyncWorker).to receive(:perform_async).with(project_1.id, anything)
          expect(Geo::ProjectSyncWorker).not_to receive(:perform_async).with(project_unhealthy_shard.id, anything)

          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      it 'performs Geo::ProjectSyncWorker for synced projects updated recently' do
        create(:geo_project_registry, :synced, :repository_dirty, project: project_1)
        create(:geo_project_registry, :synced, project: project_2)
        create(:geo_project_registry, :synced, :wiki_dirty)

        expect(Geo::ProjectSyncWorker).to receive(:perform_async).once.and_return(spy)

        subject.perform(shard_name)
      end
    end
  end
end
