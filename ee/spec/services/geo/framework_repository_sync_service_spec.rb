# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FrameworkRepositorySyncService, :geo do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:snippet) { create(:project_snippet, :public, :repository, project: project) }
  let_it_be(:replicator) { snippet.snippet_repository.replicator }

  let(:repository) { snippet.repository }
  let(:temp_repo) { subject.send(:temp_repo) }
  let(:lease_key) { "geo_sync_ssf_service:snippet_repository:#{replicator.model_record.id}" }
  let(:lease_uuid) { 'uuid' }
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

      allow(repository).to receive(:fetch_as_mirror).and_return(true)
      allow(repository).to receive(:clone_as_mirror).and_return(true)

      # Simulates a successful clone, by making sure a repository is created
      allow(temp_repo).to receive(:clone_as_mirror) do
        temp_repo.create_repository
      end

      allow(repository).to receive(:find_remote_root_ref)
                             .with(url_to_repo, anything)
                             .and_return('master')
    end

    include_context 'lease handling'

    it 'voids the failure message when it succeeds after an error' do
      registry.update!(last_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_sync_failure }.to(nil)
    end

    it 'expires repository caches' do
      expect_any_instance_of(Repository).to receive(:expire_all_method_caches).twice
      expect_any_instance_of(Repository).to receive(:expire_branch_cache).twice
      expect_any_instance_of(Repository).to receive(:expire_content_cache).once

      subject.execute
    end

    context 'with existing repository' do
      it 'fetches project repository with JWT credentials' do
        expect(repository).to receive(:fetch_as_mirror)
                                .with(url_to_repo, forced: true, http_authorization_header: anything)
                                .once

        subject.execute
      end

      it 'rescues when Gitlab::Shell::Error is raised' do
        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Shell::Error)

        expect { subject.execute }.not_to raise_error
      end

      it 'rescues exception and fires after_create hook when Gitlab::Git::Repository::NoRepository is raised' do
        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Git::Repository::NoRepository)

        expect(repository).to receive(:after_create)

        expect { subject.execute }.not_to raise_error
      end

      it 'increases retry count when Gitlab::Git::Repository::NoRepository is raised' do
        registry.save!

        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Git::Repository::NoRepository)

        subject.execute

        expect(registry.reload).to have_attributes(
          state: Geo::SnippetRepositoryRegistry::STATE_VALUES[:failed],
          retry_count: 1)
      end

      it 'marks sync as successful if no repository found' do
        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccessSnippet::ERROR_MESSAGES[:no_repo]))

        expect(replicator.class).to receive(:no_repo_message).once.and_call_original

        subject.execute

        expect(registry).to have_attributes(
          state: Geo::SnippetRepositoryRegistry::STATE_VALUES[:synced],
          missing_on_primary: true)
      end

      it 'marks sync as failed' do
        subject.execute

        expect(registry.synced?).to be true

        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Git::Repository::NoRepository)

        subject.execute

        expect(registry.reload.failed?).to be true
      end
    end

    context 'with a never synced repository' do
      context 'with geo_use_clone_on_first_sync flag enabled' do
        before do
          stub_feature_flags(geo_use_clone_on_first_sync: true)
          allow(repository).to receive(:exists?) { false }
        end

        it 'clones repository with JWT credentials' do
          expect(repository).to receive(:clone_as_mirror)
                                  .with(url_to_repo, http_authorization_header: anything)
                                  .once

          subject.execute
        end
      end

      context 'with geo_use_clone_on_first_sync flag disabled' do
        before do
          stub_feature_flags(geo_use_clone_on_first_sync: false)
          allow(repository).to receive(:exists?) { false }
        end

        it 'fetches repository with JWT credentials' do
          expect(repository).to receive(:fetch_as_mirror)
                                  .with(url_to_repo, forced: true, http_authorization_header: anything)
                                  .once

          subject.execute
        end
      end
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
              allow(repository).to receive(:find_remote_root_ref)
                                     .with(url_to_repo, anything)
                                     .and_return('feature')
            end

            it 'syncs gitattributes to info/attributes' do
              expect(repository).to receive(:copy_gitattributes)

              subject.execute
            end

            it 'updates the default branch' do
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
              expect(repository).to receive(:change_head).with('master').once

              subject.execute
            end
          end
        end
      end

      context 'when repository sync fail' do
        before do
          allow(repository).to receive(:fetch_as_mirror)
            .with(url_to_repo, forced: true, http_authorization_header: anything)
            .and_raise(Gitlab::Shell::Error.new('shell error'))
        end

        it 'sets correct values for registry record' do
          subject.execute

          expect(registry).to have_attributes(last_synced_at: be_present,
                                              retry_count: 1,
                                              retry_at: be_present,
                                              last_sync_failure: 'Error syncing repository: shell error')
        end
      end
    end

    context 'retries' do
      context 'with repository previously synced' do
        it 'tries to fetch repo' do
          registry.update!(retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD - 1)

          expect(subject).to receive(:sync_repository)

          subject.execute
        end

        it 'tries to redownload when should_be_redownloaded' do
          allow(subject).to receive(:should_be_redownloaded?) { true }

          expect(subject).to receive(:redownload_repository)

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

    context 'when repository is redownloaded' do
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

      context 'with geo_use_clone_on_first_sync flag disabled' do
        before do
          stub_feature_flags(geo_use_clone_on_first_sync: false)
          allow(subject).to receive(:should_be_redownloaded?) { true }
        end

        it 'creates a new repository and fetches with JWT credentials' do
          expect(temp_repo).to receive(:create_repository)
          expect(temp_repo).to receive(:fetch_as_mirror)
                                 .with(url_to_repo, forced: true, http_authorization_header: anything)
                                 .once
          expect(subject).to receive(:set_temp_repository_as_main)

          subject.execute
        end

        it 'cleans temporary repo after redownload' do
          expect(subject).to receive(:fetch_geo_mirror).with(target_repository: temp_repo)
          expect(subject).to receive(:clean_up_temporary_repository).twice.and_call_original
          expect(subject.gitlab_shell).to receive(:repository_exists?).twice.with(replicator.model_record.repository_storage, /.git$/)

          subject.execute
        end
      end

      context 'with geo_use_clone_on_first_sync flag enabled' do
        before do
          stub_feature_flags(geo_use_clone_on_first_sync: true)
          allow(subject).to receive(:should_be_redownloaded?) { true }
        end

        it 'clones a new repository with JWT credentials' do
          expect(temp_repo).to receive(:clone_as_mirror)
                                 .with(url_to_repo, http_authorization_header: anything)
                                 .once
          expect(subject).to receive(:set_temp_repository_as_main)

          subject.execute
        end

        it 'cleans temporary repo after redownload' do
          expect(subject).to receive(:clone_geo_mirror).with(target_repository: temp_repo)
          expect(subject).to receive(:clean_up_temporary_repository).twice.and_call_original
          expect(subject.gitlab_shell).to receive(:repository_exists?).twice.with(replicator.model_record.repository_storage, /.git$/)

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

  describe '#should_be_redownloaded?' do
    where(:force_to_redownload, :retry_count, :expected) do
      false | nil | false
      false | 0   | false
      false | 1   | false
      false | 10  | false
      false | 11  | true
      false | 12  | false
      false | 13  | true
      false | 14  | false
      false | 101 | true
      false | 102 | false
      true  | nil | true
      true  | 0   | true
      true  | 11  | true
    end

    with_them do
      it "returns the expected boolean" do
        registry.update!(retry_count: retry_count, force_to_redownload: force_to_redownload)

        expect(subject.send(:should_be_redownloaded?)).to eq(expected)
      end
    end
  end
end
