# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerification::Secondary::ShardWorker, :geo, :request_store, :clean_gitlab_redis_cache, :use_sql_query_cache_for_tracking_db, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  describe '#perform' do
    let_it_be(:secondary) { create(:geo_node) }
    let_it_be(:project_1) { create(:project) }
    let_it_be(:project_2) { create(:project) }

    let(:shard_name) { Gitlab.config.repositories.storages.each_key.first }
    let(:verification_worker) { Geo::RepositoryVerification::Secondary::SingleWorker }

    before do
      stub_current_geo_node(secondary)
      stub_exclusive_lease(renew: true)

      Gitlab::ShardHealthCache.update([shard_name])

      allow(verification_worker).to receive(:with_status).and_return(verification_worker)
    end

    context 'shard worker scheduler' do
      it 'acquires lock namespacing it per shard name' do
        subject.perform(shard_name)

        expect(subject.lease_key).to include(shard_name)
      end
    end

    it 'does not schedule jobs when shard becomes unhealthy' do
      create(:repository_state, project: project_1)

      Gitlab::ShardHealthCache.update([])

      expect(verification_worker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when no geo database is configured' do
      allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

      expect(verification_worker).not_to receive(:perform_async)

      subject.perform(shard_name)

      # We need to unstub here or the DatabaseCleaner will have issues since it
      # will appear as though the tracking DB were not available
      allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
    end

    it 'does not schedule jobs when not running on a secondary' do
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(verification_worker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when number of scheduled jobs exceeds capacity' do
      create(:project)

      is_expected.to receive(:scheduled_job_ids).and_return((1..1000).to_a).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    context 'backoff time' do
      let(:cache_key) { "#{described_class.name.underscore}:shard:#{shard_name}:skip" }

      before do
        allow(Rails.cache).to receive(:write).and_call_original
        allow(Rails.cache).to receive(:read).and_call_original
      end

      it 'sets the back off time when there are no pending items' do
        expect(Rails.cache).to receive(:write).with(cache_key, true, expires_in: 300.seconds).once

        subject.perform(shard_name)
      end

      it 'does not perform Geo::RepositoryVerification::Secondary::SingleWorker when the backoff time is set' do
        create(:repository_state, :repository_verified, project: project_1)
        create(:geo_project_registry, :synced, :repository_verification_outdated, project: project_1)

        expect(Rails.cache).to receive(:read).with(cache_key).and_return(true)

        expect(Geo::RepositoryVerification::Secondary::SingleWorker).not_to receive(:perform_async)

        subject.perform(shard_name)
      end
    end

    it 'schedule a job for each project' do
      create(:repository_state, :repository_verified, project: project_1)
      create(:repository_state, :repository_verified, project: project_2)
      create(:geo_project_registry, :synced, :repository_verification_outdated, project: project_1)
      create(:geo_project_registry, :synced, :repository_verification_outdated, project: project_2)

      expect(verification_worker).to receive(:perform_async).twice

      subject.perform(shard_name)
    end

    it 'schedule jobs for projects missing repository verification' do
      create(:repository_state, :repository_verified, :wiki_verified, project: project_1)
      missing_repository_verification = create(:geo_project_registry, :synced, :wiki_verified, project: project_1)

      expect(verification_worker).to receive(:perform_async).with(missing_repository_verification.id)

      subject.perform(shard_name)
    end

    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      it 'schedule jobs for projects missing wiki verification' do
        create(:repository_state, :repository_verified, :wiki_verified, project: project_1)
        missing_wiki_verification = create(:geo_project_registry, :synced, :repository_verified, project: project_1)

        expect(verification_worker).to receive(:perform_async).with(missing_wiki_verification.id)

        subject.perform(shard_name)
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      it 'does not schedule jobs for projects missing wiki verification' do
        create(:repository_state, :repository_verified, :wiki_verified, project: project_1)
        missing_wiki_verification = create(:geo_project_registry, :synced, :repository_verified, project: project_1)

        expect(verification_worker).not_to receive(:perform_async).with(missing_wiki_verification.id)

        subject.perform(shard_name)
      end
    end

    it 'does not schedule jobs for projects on other shards' do
      project_other_shard = create_project_on_shard('other')
      create(:repository_state, :repository_verified, :wiki_verified, project: project_other_shard)
      registry_other_shard = create(:geo_project_registry, :synced, :wiki_verified, project: project_other_shard)

      expect(verification_worker).not_to receive(:perform_async).with(registry_other_shard.id)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs for projects missing repositories on primary' do
      create(:repository_state, :repository_verified, project: project_1)
      create(:repository_state, :wiki_verified, project: project_2)
      create(:geo_project_registry, :synced, :wiki_verified, project: project_1, repository_missing_on_primary: true)
      create(:geo_project_registry, :synced, :repository_verified, project: project_2, wiki_missing_on_primary: true)

      expect(verification_worker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    # Test that when jobs are always moving forward and we're not querying the same things over and over
    context 'resource loading' do
      let_it_be(:repository_verified_1) { create(:repository_state, :repository_verified, :wiki_verified).project }
      let_it_be(:repository_verified_2) { create(:repository_state, :repository_verified, :wiki_verified).project }
      let_it_be(:repository_failed) { create(:repository_state, :repository_failed).project }
      let_it_be(:wiki_verified) { create(:repository_state, :wiki_verified).project }
      let_it_be(:repository_and_wiki_verified_1) { create(:repository_state, :repository_verified, :wiki_verified).project }
      let_it_be(:repository_and_wiki_verified_2) { create(:repository_state, :repository_verified, :wiki_verified).project }

      before do
        allow(subject).to receive(:db_retrieve_batch_size) { 1 }
      end

      it 'handles multiple batches of projects needing verification' do
        reg1 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: repository_verified_1)
        reg2 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: repository_verified_2)

        expect(verification_worker).to receive(:perform_async).with(reg1.id).once.and_call_original
        expect(verification_worker).to receive(:perform_async).with(reg2.id).once.and_call_original

        3.times do
          Sidekiq::Testing.inline! { subject.perform(shard_name) }
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        it 'handles multiple batches of projects/wikis needing verification, skipping repositories not verified on primary' do
          reg1 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: repository_verified_1)
          reg2 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: repository_verified_2)
          create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verified, project: repository_failed, primary_repository_checksummed: false)
          reg4 = create(:geo_project_registry, :synced, :wiki_verification_outdated, project: wiki_verified, primary_repository_checksummed: false)
          create(:geo_project_registry, :synced, :repository_verification_failed, :wiki_verification_failed, project: repository_and_wiki_verified_1)
          reg6 = create(:geo_project_registry, :synced, project: repository_and_wiki_verified_2)

          expect(verification_worker).to receive(:perform_async).with(reg1.id).once.and_call_original
          expect(verification_worker).to receive(:perform_async).with(reg2.id).once.and_call_original
          expect(verification_worker).to receive(:perform_async).with(reg4.id).once.and_call_original
          expect(verification_worker).to receive(:perform_async).with(reg6.id).once.and_call_original

          # In the setup phase, we stub the db_retrieve_batch_size value to 1, and
          # we have 6 registries that can be verified. So, 7 (number of registries
          # in this state + 1) is the number of times the worker needs to run to
          # ensure that enqueue secondary_singleworker once per registry pending
          # verification.
          7.times do
            Sidekiq::Testing.inline! { subject.perform(shard_name) }
          end
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: true)
        end

        it 'handles multiple batches of projects needing verification, skipping repositories not verified on primary' do
          reg1 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: repository_verified_1)
          reg2 = create(:geo_project_registry, :synced, :repository_verification_outdated, project: repository_verified_2)
          create(:geo_project_registry, :synced, :repository_verification_outdated, :wiki_verified, project: repository_failed, primary_repository_checksummed: false)
          reg4 = create(:geo_project_registry, :synced, :wiki_verification_outdated, project: wiki_verified, primary_repository_checksummed: false)
          create(:geo_project_registry, :synced, :repository_verification_failed, :wiki_verification_failed, project: repository_and_wiki_verified_1)
          reg6 = create(:geo_project_registry, :synced, project: repository_and_wiki_verified_2)

          expect(verification_worker).to receive(:perform_async).with(reg1.id).once.and_call_original
          expect(verification_worker).to receive(:perform_async).with(reg2.id).once.and_call_original
          expect(verification_worker).not_to receive(:perform_async).with(reg4.id)
          expect(verification_worker).to receive(:perform_async).with(reg6.id).once.and_call_original

          # In the setup phase, we stub the db_retrieve_batch_size value to 1, and
          # we have 6 registries that can be verified. So, 7 (number of registries
          # in this state + 1) is the number of times the worker needs to run to
          # ensure that enqueue secondary_singleworker once per registry pending
          # verification.
          7.times do
            Sidekiq::Testing.inline! { subject.perform(shard_name) }
          end
        end
      end
    end
  end
end
