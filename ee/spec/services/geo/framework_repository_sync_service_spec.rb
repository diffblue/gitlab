# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FrameworkRepositorySyncService, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }
  let_it_be(:project) { create(:project_empty_repo) }
  let_it_be(:snippet) { create(:project_snippet, :public, :repository, project: project) }
  let_it_be(:replicator) { snippet.snippet_repository.replicator }
  let_it_be(:replicator_class) { replicator.class }
  let_it_be(:model_record) { replicator.model_record }

  let(:housekeeping_incremental_repack_period) { Gitlab::CurrentSettings.housekeeping_incremental_repack_period }
  let(:repository) { model_record.repository }
  let(:temp_repo) { subject.send(:temp_repo) }
  let(:lease_key) { "geo_sync_ssf_service:snippet_repository:#{model_record.id}" }
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
      context 'when updated event was processed during a sync' do
        it 'sets reschedule sync' do
          expect_any_instance_of(registry.class)
            .to receive(:synced!)
            .once
            .and_call_original

          registry.pending!

          expect do
            subject.send(:mark_sync_as_successful)
          end.to change { subject.send(:reschedule_sync?) }.from(nil).to(true)
        end
      end
    end

    describe '#execute' do
      context 'when reschedule sync is set' do
        it 'reschedules the sync after the lease block' do
          # Stub most of execute. Only testing rescheduling after everything.
          allow(subject).to receive(:try_obtain_lease)
          # Set reschedule sync as if it occurred during replication work
          subject.send(:set_reschedule_sync)

          expect(replicator).to receive(:reschedule_sync).once

          subject.execute
        end
      end
    end
  end

  describe '#execute', :clean_gitlab_redis_shared_state, :aggregate_failures do
    shared_examples 'runs the garbage collection task specifically' do
      it 'runs the garbage collection task specifically' do
        expect_next_instance_of(Repositories::HousekeepingService, model_record, :gc) do |service|
          expect(service).to receive(:increment!).once
          expect(service).to receive(:execute).once
        end

        subject.execute
      end
    end

    shared_examples 'does not run any task specifically' do
      it 'does not run any task specifically' do
        expect_next_instance_of(Repositories::HousekeepingService, model_record, nil) do |service|
          expect(service).to receive(:increment!).once
          expect(service).to receive(:execute).once
        end

        subject.execute
      end
    end

    shared_examples 'does not run housekeeping' do
      it 'does not run housekeeping' do
        expect_next_instance_of(Repositories::HousekeepingService, model_record, nil) do |service|
          expect(service).to receive(:increment!).once
          expect(service).not_to receive(:execute)
        end

        subject.execute
      end
    end

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

      git_garbage_collect_worker_klass = double(perform_async: :the_jid) # rubocop:disable RSpec/VerifiedDoubles

      allow_any_instance_of(replicator_class.model).to receive(:git_garbage_collect_worker_klass)
                                                         .and_return(git_garbage_collect_worker_klass)
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

    context 'repository housekeeping' do
      before do
        allow(model_record).to receive(:pushes_since_gc).and_return(housekeeping_incremental_repack_period)
      end

      context 'when the replicator class supports housekeeping' do
        before do
          allow(replicator_class).to receive(:housekeeping_enabled?).and_return(true)
        end

        it 'runs housekeeping' do
          expect_next_instance_of(Repositories::HousekeepingService, model_record, anything) do |service|
            expect(service).to receive(:increment!).once
            expect(service).to receive(:execute).once.and_call_original
          end

          expect(replicator).to receive(:before_housekeeping).once.and_call_original

          subject.execute
        end

        it 'does not raise an error when a lease can not be taken' do
          allow_next_instance_of(Gitlab::ExclusiveLease, "#{model_record.class.name.underscore.pluralize}_housekeeping:#{model_record.id}", anything) do |lease|
            expect(lease).to receive(:try_obtain).and_return(nil)
          end

          allow_next_instance_of(Repositories::HousekeepingService, model_record, anything) do |service|
            expect(service).to receive(:increment!).once
            expect(service).to receive(:execute).once.and_call_original
          end

          expect { subject.execute }.not_to raise_error
        end
      end

      context 'when the replicator class does not support housekeeping' do
        before do
          allow(replicator_class).to receive(:housekeeping_enabled?).and_return(false)
        end

        it 'does not run housekeeping' do
          expect(Repositories::HousekeepingService).not_to receive(:new)

          subject.execute
        end
      end
    end

    context 'with existing repository' do
      it 'fetches git repository with JWT credentials' do
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

      context 'repository housekeeping' do
        before do
          allow(replicator_class).to receive(:housekeeping_enabled?).and_return(true)
        end

        context 'when the count is high enough' do
          before do
            allow(model_record).to receive(:pushes_since_gc).and_return(housekeeping_incremental_repack_period)
          end

          include_examples 'does not run any task specifically'

          context 'when there were errors' do
            before do
              allow(repository).to receive(:fetch_as_mirror)
                                     .with(url_to_repo, forced: true, http_authorization_header: anything)
                                     .and_raise(Gitlab::Shell::Error)
            end

            include_examples 'does not run any task specifically'
          end
        end

        context 'when the count is low enough' do
          before do
            allow(model_record).to receive(:pushes_since_gc).and_return(housekeeping_incremental_repack_period - 1)
          end

          include_examples 'does not run housekeeping'

          context 'when there were errors' do
            before do
              allow(repository).to receive(:fetch_as_mirror)
                         .with(url_to_repo, forced: true, http_authorization_header: anything)
                         .and_raise(Gitlab::Shell::Error)
            end

            include_examples 'does not run housekeeping'
          end
        end
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

        context 'repository housekeeping' do
          before do
            allow(model_record).to receive(:pushes_since_gc).and_return(0)
            allow(replicator_class).to receive(:housekeeping_enabled?).and_return(true)
          end

          include_examples 'runs the garbage collection task specifically'

          context 'when there were errors' do
            before do
              allow(repository).to receive(:clone_as_mirror)
                       .with(url_to_repo, http_authorization_header: anything)
                       .and_raise(Gitlab::Shell::Error)
            end

            include_examples 'does not run housekeeping'
          end
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

        context 'repository housekeeping' do
          before do
            allow(model_record).to receive(:pushes_since_gc).and_return(0)
            allow(replicator_class).to receive(:housekeeping_enabled?).and_return(true)
          end

          include_examples 'runs the garbage collection task specifically'

          context 'when there were errors' do
            before do
              allow(repository).to receive(:fetch_as_mirror)
                                     .with(url_to_repo, forced: true, http_authorization_header: anything)
                                     .and_raise(Gitlab::Shell::Error)
            end

            include_examples 'runs the garbage collection task specifically'
          end
        end
      end
    end

    context 'when repository is redownloaded' do
      context 'when feature flag geo_deprecate_redownload is disabled' do
        before do
          stub_feature_flags(geo_deprecate_redownload: false)
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

          expect(repository.raw).to exist
        end

        context 'with geo_use_clone_on_first_sync flag disabled' do
          before do
            stub_feature_flags(geo_use_clone_on_first_sync: false)
            allow(subject).to receive(:should_be_redownloaded?).and_return(true)
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

          context 'repository housekeeping' do
            before do
              allow(replicator_class).to receive(:housekeeping_enabled?).and_return(true)
              allow(temp_repo).to receive(:fetch_as_mirror).and_return(true)
            end

            context 'when the count is high enough' do
              before do
                allow(model_record).to receive(:pushes_since_gc).and_return(housekeeping_incremental_repack_period)
              end

              include_examples 'runs the garbage collection task specifically'

              context 'when there were errors' do
                before do
                  allow(subject).to receive(:redownload_repository).and_raise(Gitlab::Shell::Error)
                end

                include_examples 'does not run any task specifically'
              end
            end

            context 'when the count is low enough' do
              before do
                allow(model_record).to receive(:pushes_since_gc).and_return(housekeeping_incremental_repack_period - 1)
              end

              include_examples 'runs the garbage collection task specifically'

              context 'when there were errors' do
                before do
                  allow(subject).to receive(:redownload_repository).and_raise(Gitlab::Shell::Error)
                end

                include_examples 'does not run housekeeping'
              end
            end
          end
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

        context 'repository housekeeping' do
          before do
            allow(replicator_class).to receive(:housekeeping_enabled?).and_return(true)
            allow(subject).to receive(:clone_geo_mirror).and_return(true)
          end

          context 'when the count is high enough' do
            before do
              allow(model_record).to receive(:pushes_since_gc).and_return(housekeeping_incremental_repack_period)
            end

            include_examples 'runs the garbage collection task specifically'

            context 'when there were errors' do
              before do
                allow(subject).to receive(:redownload_repository).and_raise(Gitlab::Shell::Error)
              end

              include_examples 'does not run any task specifically'
            end
          end

          context 'when the count is low enough' do
            before do
              allow(model_record).to receive(:pushes_since_gc).and_return(housekeeping_incremental_repack_period - 1)
            end

            include_examples 'runs the garbage collection task specifically'

            context 'when there were errors' do
              before do
                allow(subject).to receive(:redownload_repository).and_raise(Gitlab::Shell::Error)
              end

              include_examples 'does not run housekeeping'
            end
          end
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
          # Redownload tests above mutate the repository, causing these tests to fail.
          # I'm adding this hack to avoid that since we will remove the redownload tests
          # soon anyway.
          # FF cleanup issue: https://gitlab.com/gitlab-org/gitlab/-/issues/408902
          let_it_be(:snippet) { create(:project_snippet, :public, :repository, project: project) }
          let_it_be(:replicator) { snippet.snippet_repository.replicator }
          let_it_be(:replicator_class) { replicator.class }
          let_it_be(:model_record) { replicator.model_record }

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
        context 'when feature flag geo_deprecate_redownload is enabled' do
          it 'tries to fetch repo' do
            registry.update!(retry_count: described_class::RETRIES_BEFORE_REDOWNLOAD - 1)

            expect(subject).to receive(:sync_repository)

            subject.execute
          end

          it 'does not try to redownload when force_to_redownload is true' do
            allow(registry).to receive(:force_to_redownload).and_return(true)

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
      end

      context 'no repository' do
        it 'does not raise an error' do
          registry.update!(force_to_redownload: true)

          expect(repository).to receive(:expire_exists_cache).and_call_original
          expect(subject).not_to receive(:fail_registry_sync!)

          subject.execute
        end
      end
    end

    context 'with snapshotting enabled' do
      before do
        allow(replicator).to receive(:snapshot_enabled?).and_return(true)
        allow(replicator).to receive(:snapshot_url).and_return("#{primary.url}api/v4/projects/#{project.id}/snapshot")
      end

      it_behaves_like 'sync retries use the snapshot RPC' do
        let(:retry_count) { described_class::RETRIES_BEFORE_REDOWNLOAD }

        def registry_with_retry_count(retries)
          replicator.registry.update!(retry_count: retries)
        end
      end
    end

    context 'with snapshotting disabled' do
      before do
        allow(replicator).to receive(:snapshot_enabled?).and_return(false)
      end

      # We don't need to test when the FF is enabled because snapshotting
      # only applies to the redownload flow
      context 'when feature flag geo_deprecate_redownload is disabled' do
        before do
          stub_feature_flags(geo_deprecate_redownload: false)
        end

        let(:temp_repo) { subject.send(:temp_repo) }
        let(:retry_count) { described_class::RETRIES_BEFORE_REDOWNLOAD }

        def registry_with_retry_count(retries)
          replicator.registry.update!(retry_count: retries)
        end

        def receive_create_from_snapshot
          receive(:create_from_snapshot).with(primary.snapshot_url(temp_repo), match(/^GL-Geo/)) { Gitaly::CreateRepositoryFromSnapshotResponse.new }
        end

        it 'does not attempt to snapshot for initial sync' do
          allow(repository).to receive(:exists?) { false }

          expect(repository).not_to receive_create_from_snapshot
          expect(temp_repo).not_to receive_create_from_snapshot
          expect(subject).to receive(:clone_geo_mirror)

          subject.execute
        end

        it 'does not attempt to snapshot for ordinary retries' do
          registry_with_retry_count(retry_count - 1)

          expect(repository).not_to receive_create_from_snapshot
          expect(temp_repo).not_to receive_create_from_snapshot
          expect(subject).to receive(:fetch_geo_mirror)

          subject.execute
        end

        it 'does not attempt to snapshot when registry is ready to be redownloaded' do
          registry_with_retry_count(retry_count + 1)

          expect(repository).not_to receive_create_from_snapshot
          expect(temp_repo).not_to receive_create_from_snapshot
          expect(subject).to receive(:clone_geo_mirror)

          subject.execute
        end
      end
    end
  end

  describe '#should_be_redownloaded?' do
    context 'when feature flag geo_deprecate_redownload is enabled' do
      it "returns false" do
        registry.update!(retry_count: 1000, force_to_redownload: true)

        expect(subject.send(:should_be_redownloaded?)).to be_falsey
      end
    end

    context 'when feature flag geo_deprecate_redownload is disabled' do
      before do
        stub_feature_flags(geo_deprecate_redownload: false)
      end

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
end
