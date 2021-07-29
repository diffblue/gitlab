# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::DesignRepositorySyncService do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let_it_be(:primary) { create(:geo_node, :primary) }
  let_it_be(:secondary) { create(:geo_node) }

  let(:user) { create(:user) }
  let(:project) { create(:project_empty_repo, namespace: create(:namespace, owner: user)) }

  let(:repository) { project.design_repository }
  let(:lease_key) { "geo_sync_service:design:#{project.id}" }
  let(:lease_uuid) { 'uuid'}

  subject { described_class.new(project) }

  before do
    stub_current_geo_node(secondary)
  end

  it_behaves_like 'geo base sync execution'
  it_behaves_like 'geo base sync fetch'

  describe '#execute' do
    let(:url_to_repo) { "#{primary.url}#{project.full_path}.design.git" }

    before do
      # update_highest_role uses exclusive key too:
      allow(Gitlab::ExclusiveLease).to receive(:new).and_call_original

      stub_exclusive_lease(lease_key, lease_uuid)
      stub_exclusive_lease("geo_project_housekeeping:#{project.id}")

      allow_any_instance_of(Repository).to receive(:fetch_as_mirror)
        .and_return(true)

      allow_any_instance_of(Repository)
        .to receive(:find_remote_root_ref)
        .with(url_to_repo)
        .and_return('master')

      allow_any_instance_of(Geo::ProjectHousekeepingService).to receive(:execute)
        .and_return(nil)

      allow_any_instance_of(Users::RefreshAuthorizedProjectsService).to receive(:execute)
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
      registry = create(:geo_design_registry, project: project, last_sync_failure: 'error')

      expect { subject.execute }.to change { registry.reload.last_sync_failure}.to(nil)
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

      expect(Geo::DesignRegistry.last).to have_attributes(
        retry_count: 1
      )
    end

    it 'marks sync as successful if no repository found' do
      registry = create(:geo_design_registry, project: project)

      allow(repository).to receive(:fetch_as_mirror)
        .with(url_to_repo, forced: true, http_authorization_header: anything)
        .and_raise(Gitlab::Shell::Error.new(Gitlab::GitAccessDesign::ERROR_MESSAGES[:no_repo]))

      subject.execute

      expect(registry.reload).to have_attributes(
        state: 'synced',
        missing_on_primary: true
      )
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

    it_behaves_like 'sync retries use the snapshot RPC' do
      let(:repository) { project.design_repository }
      let(:retry_count) { Geo::DesignRegistry::RETRIES_BEFORE_REDOWNLOAD }

      def registry_with_retry_count(retries)
        create(:geo_design_registry, project: project, retry_count: retries)
      end
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
end
