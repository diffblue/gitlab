# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FrameworkRepositorySyncService, :geo do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:snippet) { create(:project_snippet, :public, :repository, project: project) }
  let_it_be(:replicator) { snippet.snippet_repository.replicator }

  let(:repository) { snippet.repository }
  let(:lease_key) { "geo_sync_ssf_service:snippet_repository:#{replicator.model_record.id}" }
  let(:lease_uuid) { 'uuid'}
  let(:registry) { replicator.registry }

  subject { described_class.new(replicator) }

  before do
    stub_current_geo_node(secondary)
  end

  it_behaves_like 'geo base sync execution'
  it_behaves_like 'geo base sync fetch'

  context 'reschedules sync due to race condition instead of waiting for backfill' do
    describe '#mark_sync_as_successful' do
      let(:mark_sync_as_successful) { subject.send(:mark_sync_as_successful) }
      let(:registry) { subject.send(:registry) }

      context 'when UpdatedEvent was processed during a sync' do
        it 'reschedules the sync' do
          expect(::Geo::EventWorker).to receive(:perform_async)
          expect_any_instance_of(registry.class).to receive(:synced!).and_return(false)

          mark_sync_as_successful
        end
      end
    end
  end

  describe '#execute' do
    let(:url_to_repo) { replicator.remote_url }

    before do
      stub_exclusive_lease(lease_key, lease_uuid)

      allow_any_instance_of(Repository).to receive(:fetch_as_mirror)
        .and_return(true)

      allow_any_instance_of(Repository)
        .to receive(:find_remote_root_ref)
        .with('geo', url_to_repo, anything)
        .and_return('master')
    end

    include_context 'lease handling'

    it 'fetches project repository with JWT credentials' do
      expect(repository).to receive(:with_config)
        .with("http.#{url_to_repo}.extraHeader" => anything)
        .and_call_original

      expect(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .once

      subject.execute
    end

    it 'expires repository caches' do
      expect_any_instance_of(Repository).to receive(:expire_all_method_caches).twice
      expect_any_instance_of(Repository).to receive(:expire_branch_cache).twice
      expect_any_instance_of(Repository).to receive(:expire_content_cache).once

      subject.execute
    end

    it 'voids the failure message when it succeeds after an error' do
      registry.update!(last_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_sync_failure}.to(nil)
    end

    it 'rescues when Gitlab::Shell::Error is raised' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error)

      expect { subject.execute }.not_to raise_error
    end

    it 'rescues exception and fires after_create hook when Gitlab::Git::Repository::NoRepository is raised' do
      allow(repository).to receive(:fetch_as_mirror)
      .with(url_to_repo, remote_name: 'geo', forced: true)
      .and_raise(Gitlab::Git::Repository::NoRepository)

      expect(repository).to receive(:after_create)

      expect { subject.execute }.not_to raise_error
    end

    it 'increases retry count when Gitlab::Git::Repository::NoRepository is raised' do
      registry.save!

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(registry.reload).to have_attributes(
        state: Geo::SnippetRepositoryRegistry::STATE_VALUES[:failed],
        retry_count: 1
      )
    end

    it 'marks sync as successful if no repository found' do
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccessSnippet::ERROR_MESSAGES[:no_repo]))

      subject.execute

      expect(registry).to have_attributes(
        state: Geo::SnippetRepositoryRegistry::STATE_VALUES[:synced],
        missing_on_primary: true
      )
    end

    it 'marks sync as failed' do
      subject.execute

      expect(registry.synced?).to be true

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, remote_name: 'geo', forced: true)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(registry.reload.failed?).to be true
    end

    context 'tracking database' do
      context 'temporary repositories' do
        include_examples 'cleans temporary repositories'
      end

      context 'when repository sync succeed' do
        it 'sets last_synced_at' do
          subject.execute

          expect(registry.last_synced_at).not_to be_nil
        end

        it 'logs success with timings' do
          allow(Gitlab::Geo::Logger).to receive(:info).and_call_original
          expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :download_time_s)).and_call_original

          subject.execute
        end

        it 'sets retry_count and repository_retry_at to nil' do
          registry.update!(retry_count: 2, retry_at: Date.yesterday)

          subject.execute

          expect(registry.reload.retry_count).to be_zero
          expect(registry.retry_at).to be_nil
        end

        context 'with non empty repositories' do
          context 'when HEAD change' do
            before do
              allow(repository)
                .to receive(:find_remote_root_ref)
                .with('geo', url_to_repo, anything)
                .and_return('feature')
            end

            it 'syncs gitattributes to info/attributes' do
              expect(repository).to receive(:copy_gitattributes)

              subject.execute
            end

            it 'updates the default branch' do
              expect(repository).to receive(:with_config)
                .with("http.#{url_to_repo}.extraHeader" => anything)
                .and_call_original
                .once

              expect(repository).to receive(:change_head).with('feature').once

              subject.execute
            end
          end

          context 'when HEAD does not change' do
            it 'syncs gitattributes to info/attributes' do
              expect(repository).to receive(:copy_gitattributes)

              subject.execute
            end

            it 'updates the default branch' do
              expect(repository).to receive(:with_config)
                .with("http.#{url_to_repo}.extraHeader" => anything)
                .and_call_original
                .once

              expect(repository).to receive(:change_head).with('master').once

              subject.execute
            end
          end
        end
      end

      context 'when repository sync fail' do
        before do
          allow(repository).to receive(:fetch_as_mirror)
            .with(url_to_repo, remote_name: 'geo', forced: true)
            .and_raise(Gitlab::Shell::Error.new('shell error'))
        end

        it 'sets correct values for registry record' do
          subject.execute

          expect(registry).to have_attributes(last_synced_at: be_present,
                                              retry_count: 1,
                                              retry_at: be_present,
                                              last_sync_failure: 'Error syncing repository: shell error'
                                             )
        end

        it 'calls repository cleanup' do
          expect(repository).to receive(:clean_stale_repository_files)

          subject.execute
        end
      end
    end

    context 'retries' do
      it 'tries to fetch repo' do
        registry.update!(retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD - 1)

        expect(subject).to receive(:sync_repository)

        subject.execute
      end

      it 'sets the redownload flag to false after success' do
        registry.update!(retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD + 1, force_to_redownload: true)

        subject.execute

        expect(registry.reload.force_to_redownload).to be false
      end

      it 'tries to redownload repo' do
        registry.update!(retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD + 1)

        expect(subject).to receive(:sync_repository).and_call_original
        expect(subject.gitlab_shell).to receive(:mv_repository).twice.and_call_original

        expect(subject.gitlab_shell).to receive(:remove_repository).twice.and_call_original

        subject.execute

        repo_path = Gitlab::GitalyClient::StorageSettings.allow_disk_access do
          repository.path
        end

        expect(File.directory?(repo_path)).to be true
      end

      it 'tries to redownload repo when force_redownload flag is set' do
        registry.update!(
          retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD - 1,
          force_to_redownload: true
        )

        expect(subject).to receive(:sync_repository)

        subject.execute
      end

      it 'cleans temporary repo after redownload' do
        registry.update!(
          retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD - 1,
          force_to_redownload: true
        )

        expect(subject).to receive(:fetch_geo_mirror)
        expect(subject).to receive(:clean_up_temporary_repository).twice.and_call_original
        expect(subject.gitlab_shell).to receive(:repository_exists?).twice.with(replicator.model_record.repository_storage, /.git$/)

        subject.execute
      end

      it 'successfully redownloads the repository even if the retry time exceeds max value' do
        timestamp = Time.current.utc
        registry.update!(
          retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD + 2000,
          retry_at: timestamp,
          force_to_redownload: true
        )

        subject.execute

        # The repository should be redownloaded and cleared without errors. If
        # the timestamp were not capped, we would have seen a "timestamp out
        # of range" in the first update to the registry.
        registry.reload
        expect(registry.retry_at).to be_nil
      end

      context 'no repository' do
        it 'does not raise an error' do
          registry.update!(force_to_redownload: true)

          expect(repository).to receive(:expire_exists_cache).twice.and_call_original
          expect(subject).not_to receive(:fail_registry_sync!)

          subject.execute
        end
      end
    end

    it_behaves_like 'sync retries use the snapshot RPC' do
      let(:retry_count) { described_class::RETRIES_BEFORE_REDOWNLOAD }

      def registry_with_retry_count(retries)
        replicator.registry.update!(retry_count: retries)
      end
    end
  end
end
