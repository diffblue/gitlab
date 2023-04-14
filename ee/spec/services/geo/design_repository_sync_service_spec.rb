# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignRepositorySyncService, feature_category: :geo_replication do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo, :design_repo, namespace: create(:namespace, owner: user)) }

  let(:repository) { project.design_repository }
  let(:temp_repo) { subject.send(:temp_repo) }
  let(:lease_key) { "geo_sync_service:design:#{project.id}" }
  let(:lease_uuid) { 'uuid' }
  let(:url_to_repo) { "#{primary.url}#{project.full_path}.design.git" }

  subject { described_class.new(project) }

  before do
    stub_current_geo_node(secondary)
  end

  it_behaves_like 'geo base sync execution'
  it_behaves_like 'geo base sync fetch'

  describe '#execute' do
    before do
      # update_highest_role uses exclusive key too:
      allow(Gitlab::ExclusiveLease).to receive(:new).and_call_original

      stub_exclusive_lease(lease_key, lease_uuid)
      stub_exclusive_lease("geo_project_housekeeping:#{project.id}")

      allow(repository).to receive(:fetch_as_mirror).and_return(true)
      allow(repository).to receive(:clone_as_mirror).and_return(true)

      allow(repository).to receive(:find_remote_root_ref)
                             .with(url_to_repo, anything)
                             .and_return('master')

      allow_any_instance_of(Users::RefreshAuthorizedProjectsService).to receive(:execute)
        .and_return(nil)
    end

    include_context 'lease handling'

    it 'voids the failure message when it succeeds after an error' do
      registry = create(:geo_design_registry, project: project, last_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_sync_failure }.to(nil)
    end

    it 'execute repository cache expiration' do
      expect(subject).to receive(:expire_repository_caches)

      subject.execute
    end

    context 'with existing repository' do
      before do
        subject.send(:ensure_repository)
      end

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

      it 'rescues exception when Gitlab::Git::Repository::NoRepository is raised' do
        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Git::Repository::NoRepository)

        expect { subject.execute }.not_to raise_error
      end

      it 'increases retry count when Gitlab::Git::Repository::NoRepository is raised' do
        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Git::Repository::NoRepository)

        subject.execute

        expect(Geo::DesignRegistry.last).to have_attributes(retry_count: 1)
      end

      it 'marks sync as successful if no repository found' do
        registry = create(:geo_design_registry, project: project)

        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccessDesign::ERROR_MESSAGES[:no_repo]))

        subject.execute

        expect(registry.reload).to have_attributes(state: 'synced', missing_on_primary: true)
      end

      it 'marks resync as true after a failure' do
        described_class.new(project).execute

        expect(Geo::DesignRegistry.last.state).to eq 'synced'

        allow(repository).to receive(:fetch_as_mirror)
                               .with(url_to_repo, forced: true, http_authorization_header: anything)
                               .and_raise(Gitlab::Git::Repository::NoRepository)

        subject.execute

        expect(Geo::DesignRegistry.last.state).to eq 'failed'
      end
    end

    context 'with a never synced repository' do
      it 'clones project repository with JWT credentials' do
        allow(repository).to receive(:exists?) { false }

        expect(repository).to receive(:clone_as_mirror)
                                .with(url_to_repo, http_authorization_header: anything)
                                .once

        subject.execute
      end
    end

    it_behaves_like 'sync retries use the snapshot RPC' do
      let(:retry_count) { Geo::DesignRegistry::RETRIES_BEFORE_REDOWNLOAD }

      def registry_with_retry_count(retries)
        create(:geo_design_registry, project: project, retry_count: retries)
      end
    end
  end

  describe '#expire_repository_caches' do
    it 'expires repository caches' do
      subject.send(:ensure_repository)

      expect(repository).to receive(:expire_all_method_caches).once
      expect(repository).to receive(:expire_branch_cache).once
      expect(repository).to receive(:expire_content_cache).once

      subject.send(:expire_repository_caches)
    end
  end

  context 'race condition when RepositoryUpdatedEvent was processed during a sync' do
    let(:registry) { subject.send(:registry) }

    it 'reschedules the sync' do
      expect(::Geo::DesignRepositorySyncWorker).to receive(:perform_async)
      expect(registry).to receive(:finish_sync!).and_return(false)

      subject.send(:mark_sync_as_successful)
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

        subject.execute
      end

      it 'cleans temporary repo after redownload' do
        expect(subject).to receive(:clone_geo_mirror).with(target_repository: temp_repo)
        expect(subject).to receive(:clean_up_temporary_repository).twice.and_call_original

        subject.execute
      end
    end
  end
end
