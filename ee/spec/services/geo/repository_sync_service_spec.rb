# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RepositorySyncService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:project) { create(:project_empty_repo) }

  let(:repository) { project.repository }
  let(:temp_repo) { subject.send(:temp_repo) }
  let(:lease_key) { "geo_sync_service:repository:#{project.id}" }
  let(:lease_uuid) { 'uuid' }
  let(:url_to_repo) { "#{primary.url}#{project.full_path}.git" }

  subject { described_class.new(project) }

  before do
    stub_current_geo_node(secondary)
  end

  it_behaves_like 'geo base sync execution'
  it_behaves_like 'geo base sync fetch'
  it_behaves_like 'reschedules sync due to race condition instead of waiting for backfill'

  describe '#execute' do
    before do
      stub_exclusive_lease(lease_key, lease_uuid)
      stub_exclusive_lease("geo_project_housekeeping:#{project.id}")

      allow(repository).to receive(:fetch_as_mirror).and_return(true)
      allow(repository).to receive(:clone_as_mirror).and_return(true)

      # Simulates a successful clone, by making sure a repository is created
      allow(temp_repo).to receive(:clone_as_mirror) do
        temp_repo.create_repository
      end

      allow(repository)
        .to receive(:find_remote_root_ref)
        .with(url_to_repo, anything)
        .and_return('master')

      allow_any_instance_of(Geo::ProjectHousekeepingService).to receive(:execute)
        .and_return(nil)
    end

    include_context 'lease handling'

    it 'fetches project repository with JWT credentials' do
      expect(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, forced: true, http_authorization_header: anything)
        .once

      subject.execute
    end

    it 'expires repository caches' do
      expect_any_instance_of(Repository).to receive(:expire_all_method_caches).once
      expect_any_instance_of(Repository).to receive(:expire_branch_cache).once
      expect_any_instance_of(Repository).to receive(:expire_content_cache).once

      subject.execute
    end

    it 'voids the failure message when it succeeds after an error' do
      registry = create(:geo_project_registry, project: project, last_repository_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_repository_sync_failure }.to(nil)
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
      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, forced: true, http_authorization_header: anything)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(Geo::ProjectRegistry.last).to have_attributes(
        resync_repository: true,
        repository_retry_count: 1
      )
    end

    it 'marks sync as successful if no repository found' do
      registry = create(:geo_project_registry, project: project)

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, forced: true, http_authorization_header: anything)
        .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]))

      subject.execute

      expect(registry.reload).to have_attributes(
        resync_repository: false,
        last_repository_successful_sync_at: be_present,
        repository_missing_on_primary: true
      )
    end

    it 'marks resync as true after a failure' do
      described_class.new(project).execute

      expect(Geo::ProjectRegistry.last.resync_repository).to be false

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, forced: true, http_authorization_header: anything)
        .and_raise(Gitlab::Git::Repository::NoRepository)

      subject.execute

      expect(Geo::ProjectRegistry.last.resync_repository).to be true
    end

    context 'repository presumably exists on primary' do
      it 'increases retry count if no repository found' do
        registry = create(:geo_project_registry, project: project)
        create(:repository_state, :repository_verified, project: project)

        allow(repository).to receive(:fetch_as_mirror)
          .with(url_to_repo, forced: true, http_authorization_header: anything)
          .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccess::ERROR_MESSAGES[:no_repo]))

        subject.execute

        expect(registry.reload).to have_attributes(
          resync_repository: true,
          repository_retry_count: 1
        )
      end
    end

    it 'marks primary_repository_checksummed as true when repository has been verified on primary' do
      create(:repository_state, :repository_verified, project: project)
      registry = create(:geo_project_registry, project: project, primary_repository_checksummed: false)

      expect { subject.execute }.to change { registry.reload.primary_repository_checksummed }.from(false).to(true)
    end

    it 'marks primary_repository_checksummed as false when repository has not been verified on primary' do
      create(:repository_state, :repository_failed, project: project)
      registry = create(:geo_project_registry, project: project, primary_repository_checksummed: true)

      expect { subject.execute }.to change { registry.reload.primary_repository_checksummed }.from(true).to(false)
    end

    context 'tracking database' do
      context 'temporary repositories' do
        include_examples 'cleans temporary repositories' do
          let(:repository) { project.repository }
        end
      end

      it 'creates a new registry if does not exists' do
        expect { subject.execute }.to change(Geo::ProjectRegistry, :count).by(1)
      end

      it 'does not create a new registry if one exist' do
        create(:geo_project_registry, project: project)

        expect { subject.execute }.not_to change(Geo::ProjectRegistry, :count)
      end

      context 'when repository sync succeed' do
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        it 'sets last_repository_synced_at' do
          subject.execute

          expect(registry.last_repository_synced_at).not_to be_nil
        end

        it 'sets last_repository_successful_sync_at' do
          subject.execute

          expect(registry.last_repository_successful_sync_at).not_to be_nil
        end

        it 'resets the repository_verification_checksum_sha' do
          subject.execute

          expect(registry.repository_verification_checksum_sha).to be_nil
        end

        it 'resets the last_repository_verification_failure' do
          subject.execute

          expect(registry.last_repository_verification_failure).to be_nil
        end

        it 'resets the repository_checksum_mismatch' do
          subject.execute

          expect(registry.repository_checksum_mismatch).to eq false
        end

        it 'logs success with timings' do
          allow(Gitlab::Geo::Logger).to receive(:info).and_call_original
          expect(Gitlab::Geo::Logger).to receive(:info).with(hash_including(:message, :update_delay_s, :download_time_s)).and_call_original

          subject.execute
        end

        it 'sets repository_retry_count and repository_retry_at to nil' do
          registry = create(:geo_project_registry, project: project, repository_retry_count: 2, repository_retry_at: Date.yesterday)

          subject.execute

          expect(registry.reload.repository_retry_count).to be_nil
          expect(registry.repository_retry_at).to be_nil
        end

        context 'with non empty repositories' do
          let(:project) { create(:project, :repository) }

          context 'when HEAD change' do
            before do
              allow(project.repository)
                .to receive(:find_remote_root_ref)
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
        let(:registry) { Geo::ProjectRegistry.find_by(project_id: project.id) }

        before do
          allow(repository).to receive(:fetch_as_mirror)
            .with(url_to_repo, forced: true, http_authorization_header: anything)
            .and_raise(Gitlab::Shell::Error.new('shell error'))
        end

        it 'sets correct values for registry record' do
          subject.execute

          expect(registry).to have_attributes(last_repository_synced_at: be_present,
                                              last_repository_successful_sync_at: nil,
                                              repository_retry_count: 1,
                                              repository_retry_at: be_present,
                                              last_repository_sync_failure: 'Error syncing repository: shell error'
                                             )
        end
      end
    end

    context 'retries' do
      context 'with repository previously synced' do
        context 'when feature flag geo_deprecate_redownload is enabled' do
          it 'tries to fetch repo' do
            create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1)

            expect(subject).to receive(:sync_repository)

            subject.execute
          end

          it 'sets the redownload flag to false after success' do
            registry = create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 1, force_to_redownload_repository: true)

            subject.execute

            expect(registry.reload.force_to_redownload_repository).to be false
          end

          it 'does not try to redownload repo when there are many retries' do
            create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 1)

            expect(subject).to receive(:sync_repository)
            expect(subject).not_to receive(:redownload_repository)

            subject.execute
          end

          it 'does not try to redownload repo when force_redownload flag is set' do
            create(
              :geo_project_registry,
              project: project,
              repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1,
              force_to_redownload_repository: true
            )

            expect(subject).to receive(:sync_repository)
            expect(subject).not_to receive(:redownload_repository)

            subject.execute
          end
        end

        context 'when feature flag geo_deprecate_redownload is disabled' do
          before do
            stub_feature_flags(geo_deprecate_redownload: false)
          end

          it 'tries to fetch repo' do
            create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1)

            expect(subject).to receive(:sync_repository)

            subject.execute
          end

          it 'sets the redownload flag to false after success' do
            registry = create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 1, force_to_redownload_repository: true)

            subject.execute

            expect(registry.reload.force_to_redownload_repository).to be false
          end

          it 'tries to redownload repo' do
            create(:geo_project_registry, project: project, repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 1)

            expect(subject).to receive(:sync_repository).and_call_original
            expect(subject.gitlab_shell).to receive(:mv_repository).twice.and_call_original

            expect(subject.gitlab_shell).to receive(:remove_repository).twice.and_call_original

            subject.execute

            expect(project.repository.raw).to exist
          end

          it 'tries to redownload repo when force_redownload flag is set' do
            create(
              :geo_project_registry,
              project: project,
              repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1,
              force_to_redownload_repository: true
            )

            expect(subject).to receive(:sync_repository)

            subject.execute
          end

          it 'cleans temporary repo after redownload' do
            create(
              :geo_project_registry,
              project: project,
              repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD - 1,
              force_to_redownload_repository: true
            )

            expect(subject).to receive(:clone_geo_mirror).with(target_repository: temp_repo)
            expect(subject).to receive(:clean_up_temporary_repository).twice.and_call_original
            expect(subject.gitlab_shell).to receive(:repository_exists?).twice.with(project.repository_storage, /.git$/)

            subject.execute
          end

          it 'successfully redownloads the repository even if the retry time exceeds max value' do
            timestamp = Time.current.utc
            registry = create(
              :geo_project_registry,
              project: project,
              repository_retry_count: Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD + 2000,
              repository_retry_at: timestamp,
              force_to_redownload_repository: true
            )

            subject.execute

            # The repository should be redownloaded and cleared without errors. If
            # the timestamp were not capped, we would have seen a "timestamp out
            # of range" in the first update to the project registry.
            registry.reload
            expect(registry.repository_retry_at).to be_nil
          end
        end
      end

      context 'no repository' do
        let(:project) { create(:project) }

        it 'does not raise an error' do
          create(:geo_project_registry, project: project, force_to_redownload_repository: true)

          expect(project.repository).to receive(:expire_exists_cache).twice.and_call_original
          expect(subject).not_to receive(:fail_registry_sync!)

          subject.execute
        end
      end
    end

    it_behaves_like 'sync retries use the snapshot RPC' do
      let(:repository) { project.repository }
      let(:retry_count) { Geo::ProjectRegistry::RETRIES_BEFORE_REDOWNLOAD }

      def registry_with_retry_count(retries)
        create(:geo_project_registry, project: project, repository_retry_count: retries, wiki_retry_count: retries)
      end
    end
  end

  context 'repository housekeeping' do
    let(:registry) { Geo::ProjectRegistry.find_or_initialize_by(project_id: project.id) }

    it 'increases sync count after execution' do
      expect { subject.execute }.to change { registry.syncs_since_gc }.by(1)
    end

    it 'initiate housekeeping at end of execution' do
      expect_any_instance_of(Geo::ProjectHousekeepingService).to receive(:execute)

      subject.execute
    end
  end

  context 'when the repository is redownloaded' do
    context 'with geo_use_clone_on_first_sync flag disabled' do
      before do
        stub_feature_flags(geo_use_clone_on_first_sync: false)
        allow(subject).to receive(:redownload?).and_return(true)
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

        subject.execute
      end

      it "indicates the repository is not new even with errors" do
        allow(subject).to receive(:redownload_repository).and_raise(Gitlab::Shell::Error)
        expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: false).and_call_original

        subject.execute
      end
    end

    context 'with geo_use_clone_on_first_sync flag enabled' do
      before do
        stub_feature_flags(geo_use_clone_on_first_sync: true)
        allow(subject).to receive(:redownload?).and_return(true)
      end

      it 'clones a new repository with JWT credentials' do
        expect(temp_repo).to receive(:clone_as_mirror)
                               .with(url_to_repo, http_authorization_header: anything)
                               .once
        expect(subject).to receive(:set_temp_repository_as_main)
        expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: true).and_call_original

        subject.execute
      end

      it 'cleans temporary repo after redownload' do
        expect(subject).to receive(:clone_geo_mirror).with(target_repository: temp_repo)
        expect(subject).to receive(:clean_up_temporary_repository).twice.and_call_original

        subject.execute
      end
    end
  end

  context 'when repository did not exist' do
    before do
      allow(repository).to receive(:exists?).and_return(false)
      allow(subject).to receive(:fetch_geo_mirror).and_return(nil)
      allow(subject).to receive(:clone_geo_mirror).and_return(nil)
    end

    context 'with geo_use_clone_on_first_sync flag enabled' do
      before do
        stub_feature_flags(geo_use_clone_on_first_sync: true)
      end

      it "dont indicates the repository is new when there were errors" do
        allow(subject).to receive(:clone_geo_mirror).and_raise(Gitlab::Shell::Error)

        expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: false).and_call_original

        subject.execute
      end

      it "indicates the repository is new if successful" do
        expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: true).and_call_original

        subject.execute
      end
    end

    context 'with geo_use_clone_on_first_sync flag disabled' do
      before do
        stub_feature_flags(geo_use_clone_on_first_sync: false)
      end

      it "indicates the repository is new when there were errors" do
        allow(subject).to receive(:fetch_geo_mirror).and_raise(Gitlab::Shell::Error)

        expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: true).and_call_original

        subject.execute
      end

      it "indicates the repository is new if successful" do
        expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: true).and_call_original

        subject.execute
      end
    end
  end

  context 'when repository already existed' do
    it "indicates the repository is not new" do
      expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: false).and_call_original

      subject.execute
    end

    it "indicates the repository is not new even with errors" do
      allow(subject).to receive(:fetch_geo_mirror).and_raise(Gitlab::Shell::Error)
      expect(Geo::ProjectHousekeepingService).to receive(:new).with(project, new_repository: false).and_call_original

      subject.execute
    end
  end
end
