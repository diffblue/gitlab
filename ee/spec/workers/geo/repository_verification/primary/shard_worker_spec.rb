# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositoryVerification::Primary::ShardWorker, :clean_gitlab_redis_cache, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }

  let(:shard_name) { Gitlab.config.repositories.storages.each_key.first }
  let(:primary_singleworker) { Geo::RepositoryVerification::Primary::SingleWorker }

  before_all do
    Project.delete_all
  end

  before do
    stub_current_geo_node(primary)

    allow(primary_singleworker).to receive(:with_status).and_return(primary_singleworker)
  end

  describe '#perform' do
    before do
      stub_exclusive_lease(renew: true)

      Gitlab::ShardHealthCache.update([shard_name])
    end

    context 'shard worker scheduler' do
      it 'acquires lock namespacing it per shard name' do
        subject.perform(shard_name)

        expect(subject.lease_key).to include(shard_name)
      end
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for each project' do
      create_list(:project, 2)

      expect(primary_singleworker).to receive(:perform_async).twice

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for verified projects updated recently' do
      verified_project = create(:project)
      repository_outdated = create(:project)
      wiki_outdated = create(:project)

      create(:repository_state, :repository_verified, :wiki_verified, project: verified_project)
      create(:repository_state, :repository_outdated, project: repository_outdated)
      create(:repository_state, :wiki_outdated, project: wiki_outdated)

      expect(primary_singleworker).not_to receive(:perform_async).with(verified_project.id)
      expect(primary_singleworker).to receive(:perform_async).with(repository_outdated.id)
      expect(primary_singleworker).to receive(:perform_async).with(wiki_outdated.id)

      subject.perform(shard_name)
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects missing repository verification' do
      missing_repository_verification = create(:project)

      create(:repository_state, :wiki_verified, project: missing_repository_verification)

      expect(primary_singleworker).to receive(:perform_async).with(missing_repository_verification.id)

      subject.perform(shard_name)
    end

    context 'with geo_project_wiki_repository_replication feature flag disabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: false)
      end

      it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects missing wiki verification' do
        missing_wiki_verification = create(:project)

        create(:repository_state, :repository_verified, project: missing_wiki_verification)

        expect(primary_singleworker).to receive(:perform_async).with(missing_wiki_verification.id)

        subject.perform(shard_name)
      end

      it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects where wiki verification failed' do
        wiki_verification_failed = create(:project)

        create(:repository_state, :repository_verified, :wiki_failed, project: wiki_verification_failed)

        expect(primary_singleworker).to receive(:perform_async).with(wiki_verification_failed.id)

        subject.perform(shard_name)
      end
    end

    context 'with geo_project_wiki_repository_replication feature flag enabled' do
      before do
        stub_feature_flags(geo_project_wiki_repository_replication: true)
      end

      it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker for projects missing wiki verification' do
        missing_wiki_verification = create(:project)

        create(:repository_state, :repository_verified, project: missing_wiki_verification)

        expect(primary_singleworker).not_to receive(:perform_async).with(missing_wiki_verification.id)

        subject.perform(shard_name)
      end

      it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker for projects where wiki verification failed' do
        wiki_verification_failed = create(:project)

        create(:repository_state, :repository_verified, :wiki_failed, project: wiki_verification_failed)

        expect(primary_singleworker).not_to receive(:perform_async).with(wiki_verification_failed.id)

        subject.perform(shard_name)
      end
    end

    it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects where repository verification failed' do
      repository_verification_failed = create(:project)

      create(:repository_state, :repository_failed, :wiki_verified, project: repository_verification_failed)

      expect(primary_singleworker).to receive(:perform_async).with(repository_verification_failed.id)

      subject.perform(shard_name)
    end

    context 'reverification' do
      context 'feature geo_repository_reverification flag is enabled' do
        before do
          stub_feature_flags(geo_repository_reverification: true)
        end

        it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects where repository should be reverified' do
          project_to_be_reverified = create(:project)

          create(:repository_state, :repository_verified, :wiki_verified,
            project: project_to_be_reverified, last_repository_verification_ran_at: 10.days.ago)

          expect(primary_singleworker).to receive(:perform_async).with(project_to_be_reverified.id)

          subject.perform(shard_name)
        end

        context 'with geo_project_wiki_repository_replication feature flag disabled' do
          before do
            stub_feature_flags(geo_project_wiki_repository_replication: false)
          end

          it 'performs Geo::RepositoryVerification::Primary::SingleWorker for projects where wiki should be reverified' do
            project_to_be_reverified = create(:project)

            create(:repository_state, :repository_verified, :wiki_verified,
              project: project_to_be_reverified, last_wiki_verification_ran_at: 10.days.ago)

            expect(primary_singleworker).to receive(:perform_async).with(project_to_be_reverified.id)

            subject.perform(shard_name)
          end
        end

        context 'with geo_project_wiki_repository_replication feature flag enabled' do
          before do
            stub_feature_flags(geo_project_wiki_repository_replication: true)
          end

          it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker for projects where wiki should be reverified' do
            project_to_be_reverified = create(:project)

            create(:repository_state, :repository_verified, :wiki_verified,
              project: project_to_be_reverified, last_wiki_verification_ran_at: 10.days.ago)

            expect(primary_singleworker).not_to receive(:perform_async).with(project_to_be_reverified.id)

            subject.perform(shard_name)
          end
        end
      end

      context 'feature geo_repository_reverification flag is disabled' do
        before do
          stub_feature_flags(geo_repository_reverification: false)
        end

        it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker for projects where repository should be reverified' do
          create(:repository_state, :repository_verified, :wiki_verified,
            last_repository_verification_ran_at: 10.days.ago)

          expect(primary_singleworker).not_to receive(:perform_async)

          subject.perform(shard_name)
        end

        it 'does not Geo::RepositoryVerification::Primary::SingleWorker for projects where wiki should be reverified' do
          create(:repository_state, :repository_verified, :wiki_verified,
            last_wiki_verification_ran_at: 10.days.ago)

          expect(primary_singleworker).not_to receive(:perform_async)

          subject.perform(shard_name)
        end
      end
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker when shard becomes unhealthy' do
      create(:project)

      Gitlab::ShardHealthCache.update([])

      expect(primary_singleworker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker when not running on a primary' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect(primary_singleworker).not_to receive(:perform_async)

      subject.perform(shard_name)
    end

    it 'does not schedule jobs when number of scheduled jobs exceeds capacity' do
      create(:project)

      is_expected.to receive(:scheduled_job_ids).and_return((1..1000).to_a).at_least(:once)
      is_expected.not_to receive(:schedule_job)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker for projects on unhealthy shards' do
      healthy_unverified = create(:project)
      missing_not_verified = create(:project)
      missing_not_verified.update_column(:repository_storage, 'unknown')
      missing_outdated = create(:project)
      missing_outdated.update_column(:repository_storage, 'unknown')

      create(:repository_state, :repository_outdated, project: missing_outdated)

      expect(primary_singleworker).to receive(:perform_async).with(healthy_unverified.id)
      expect(primary_singleworker).not_to receive(:perform_async).with(missing_not_verified.id)
      expect(primary_singleworker).not_to receive(:perform_async).with(missing_outdated.id)

      Sidekiq::Testing.inline! { subject.perform(shard_name) }
    end

    context 'backoff time' do
      let(:cache_key) { "#{described_class.name.underscore}:shard:#{shard_name}:skip" }

      before do
        allow(Rails.cache).to receive(:read).and_call_original
        allow(Rails.cache).to receive(:write).and_call_original
      end

      it 'sets the back off time when there are no pending items' do
        expect(Rails.cache).to receive(:write).with(cache_key, true, expires_in: 300.seconds).once

        subject.perform(shard_name)
      end

      it 'does not perform Geo::RepositoryVerification::Primary::SingleWorker when the backoff time is set' do
        repository_outdated = create(:project)
        create(:repository_state, :repository_outdated, project: repository_outdated)

        expect(Rails.cache).to receive(:read).with(cache_key).and_return(true)

        expect(Geo::RepositoryVerification::Primary::SingleWorker).not_to receive(:perform_async)

        subject.perform(shard_name)
      end
    end

    # test that jobs are always moving forward and we're not querying the same things
    # over and over
    describe 'resource loading' do
      before do
        allow(subject).to receive(:db_retrieve_batch_size) { 1 }
      end

      let(:project_repo_verified) { create(:repository_state, :repository_verified).project }
      let(:project_repo_failed) { create(:repository_state, :repository_failed).project }
      let(:project_wiki_verified) { create(:repository_state, :wiki_verified).project }
      let(:project_wiki_failed) { create(:repository_state, :wiki_failed).project }
      let(:project_both_verified) { create(:repository_state, :repository_verified, :wiki_verified).project }
      let(:project_both_failed) { create(:repository_state, :repository_failed, :wiki_failed).project }
      let(:project_repo_unverified) { create(:repository_state).project }
      let(:project_wiki_unverified) { create(:repository_state, :repository_verified).project }
      let(:project_repo_failed_wiki_verified) { create(:repository_state, :repository_failed, :wiki_verified).project }
      let(:project_repo_verified_wiki_failed) { create(:repository_state, :repository_verified, :wiki_failed).project }
      let(:project_repo_reverify) { create(:repository_state, :repository_verified, :wiki_verified, last_repository_verification_ran_at: 10.days.ago).project }
      let(:project_wiki_reverify) { create(:repository_state, :repository_verified, :wiki_verified, last_wiki_verification_ran_at: 10.days.ago).project }

      context 'with geo_project_wiki_repository_replication feature flag disabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: false)
        end

        it 'handles multiple batches of projects/wikis needing verification' do
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_unverified.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_wiki_unverified.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_verified.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_wiki_verified.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_both_failed.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_failed_wiki_verified.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_verified_wiki_failed.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_reverify.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_wiki_reverify.id).once.and_call_original

          # In the setup phase, we stub the db_retrieve_batch_size value to 1, and
          # we have 9 registries that can be verified. So, 10 (number of registries
          # in this state + 1) is the number of times the worker needs to run to
          # ensure that enqueue primary_singleworker once per registry pending
          # verification.
          10.times do
            Sidekiq::Testing.inline! { subject.perform(shard_name) }
          end
        end
      end

      context 'with geo_project_wiki_repository_replication feature flag enabled' do
        before do
          stub_feature_flags(geo_project_wiki_repository_replication: true)
        end

        it 'handles multiple batches of projects needing verification' do
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_unverified.id).once.and_call_original
          expect(primary_singleworker).not_to receive(:perform_async).with(project_wiki_unverified.id)
          expect(primary_singleworker).not_to receive(:perform_async).with(project_repo_verified.id)
          expect(primary_singleworker).to receive(:perform_async).with(project_wiki_verified.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_both_failed.id).once.and_call_original
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_failed_wiki_verified.id).once.and_call_original
          expect(primary_singleworker).not_to receive(:perform_async).with(project_repo_verified_wiki_failed.id)
          expect(primary_singleworker).to receive(:perform_async).with(project_repo_reverify.id).once.and_call_original
          expect(primary_singleworker).not_to receive(:perform_async).with(project_wiki_reverify.id)

          # In the setup phase, we stub the db_retrieve_batch_size value to 1, and
          # we have 9 registries that can be verified. So, 10 (number of registries
          # in this state + 1) is the number of times the worker needs to run to
          # ensure that enqueue primary_singleworker once per registry pending
          # verification.
          10.times do
            Sidekiq::Testing.inline! { subject.perform(shard_name) }
          end
        end
      end
    end
  end
end
