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

    context 'tracking database' do
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
  end
end
