# frozen_string_literal: true

RSpec.shared_examples 'geo base sync execution' do
  describe '#execute' do
    let(:project) { build('project')}

    context 'when can acquire exclusive lease' do
      before do
        exclusive_lease = double(:exclusive_lease, try_obtain: 12345)
        expect(subject).to receive(:exclusive_lease).and_return(exclusive_lease)
      end

      it 'executes the synchronization' do
        expect(subject).to receive(:sync_repository)

        subject.execute
      end
    end

    context 'when exclusive lease is not acquired' do
      before do
        exclusive_lease = double(:exclusive_lease, try_obtain: nil)
        expect(subject).to receive(:exclusive_lease).and_return(exclusive_lease)
      end

      it 'is does not execute synchronization' do
        expect(subject).not_to receive(:sync_repository)

        subject.execute
      end
    end
  end
end

RSpec.shared_examples 'cleans temporary repositories' do
  context 'there is a leftover repository' do
    let(:temp_repo_path) { "@geo-temporary/#{repository.disk_path}" }

    it 'removes leftover repository' do
      gitlab_shell = instance_double('Gitlab::Shell')

      allow(subject).to receive(:gitlab_shell).and_return(gitlab_shell)
      allow(subject).to receive(:fetch_geo_mirror)

      expect(gitlab_shell).to receive(:repository_exists?).and_return(true)
      expect(gitlab_shell).to receive(:remove_repository).with(project.repository_storage, temp_repo_path)

      subject.execute
    end
  end
end

RSpec.shared_examples 'geo base sync fetch' do
  describe '#sync_repository' do
    it 'tells registry that sync will start now' do
      registry = subject.send(:registry)
      allow_any_instance_of(registry.class).to receive(:start_sync!)

      subject.send(:sync_repository)
    end
  end

  describe '#fetch_repository' do
    let(:fetch_repository) { subject.send(:fetch_repository) }

    before do
      allow(subject).to receive(:fetch_geo_mirror).and_return(true)
    end

    it 'cleans up temporary repository' do
      is_expected.to receive(:clean_up_temporary_repository)

      fetch_repository
    end

    it 'fetches repository from geo node' do
      is_expected.to receive(:fetch_geo_mirror).with(subject.send(:repository))

      fetch_repository
    end

    context 'repository does not exist' do
      before do
        allow_any_instance_of(Repository).to receive(:exists?) { false }
      end

      it 'ensures repository is created' do
        is_expected.to receive(:ensure_repository)

        fetch_repository
      end
    end
  end
end

RSpec.shared_examples 'sync retries use the snapshot RPC' do
  context 'snapshot synchronization method' do
    before do
      allow(subject).to receive(:temp_repo) { repository }
    end

    def receive_create_from_snapshot
      receive(:create_from_snapshot).with(primary.snapshot_url(repository), match(/^GL-Geo/)) { Gitaly::CreateRepositoryFromSnapshotResponse.new }
    end

    it 'does not attempt to snapshot for initial sync' do
      expect(repository).not_to receive_create_from_snapshot
      expect(subject).to receive(:fetch_geo_mirror).with(repository)

      subject.execute
    end

    it 'does not attempt to snapshot for ordinary retries' do
      registry_with_retry_count(retry_count - 1)

      expect(repository).not_to receive_create_from_snapshot
      expect(subject).to receive(:fetch_geo_mirror).with(repository)

      subject.execute
    end

    context 'registry is ready to be snapshotted' do
      let!(:registry) { registry_with_retry_count(retry_count + 1) }

      it 'attempts to snapshot' do
        expect(repository).to receive_create_from_snapshot
        expect(subject).not_to receive(:fetch_geo_mirror).with(repository)
        expect(subject).to receive(:set_temp_repository_as_main)

        subject.execute
      end

      it 'attempts to fetch if snapshotting raises an exception' do
        expect(repository).to receive_create_from_snapshot.and_raise(ArgumentError)
        expect(subject).to receive(:fetch_geo_mirror).with(repository)

        subject.execute
      end
    end
  end
end

RSpec.shared_examples 'reschedules sync due to race condition instead of waiting for backfill' do
  describe '#mark_sync_as_successful' do
    let(:mark_sync_as_successful) { subject.send(:mark_sync_as_successful) }
    let(:registry) { subject.send(:registry) }

    context 'when RepositoryUpdatedEvent was processed during a sync' do
      it 'reschedules the sync' do
        expect(::Geo::ProjectSyncWorker).to receive(:perform_async)
        expect(registry).to receive(:finish_sync!).and_return(false)

        mark_sync_as_successful
      end
    end
  end
end

RSpec.shared_context 'lease handling' do
  it 'returns the lease when succeed' do
    expect_to_cancel_exclusive_lease(lease_key, lease_uuid)

    subject.execute
  end

  it 'returns the lease when sync fail' do
    allow(repository).to receive(:fetch_as_mirror)
      .with(url_to_repo, forced: true, http_authorization_header: anything)
      .and_raise(Gitlab::Shell::Error)

    expect_to_cancel_exclusive_lease(lease_key, lease_uuid)

    subject.execute
  end

  it 'does not fetch project repository if cannot obtain a lease' do
    stub_exclusive_lease_taken(lease_key)

    expect(repository).not_to receive(:fetch_as_mirror)

    subject.execute
  end
end
