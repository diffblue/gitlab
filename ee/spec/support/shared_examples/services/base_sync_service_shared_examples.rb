# frozen_string_literal: true

RSpec.shared_examples 'geo base sync execution' do
  describe '#execute' do
    let(:project) { build('project') }

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
      allow(subject).to receive(:clone_geo_mirror).and_return(true)
      allow(repository).to receive(:update_root_ref)
    end

    it 'syncs the HEAD ref' do
      expect(repository).to receive(:update_root_ref)

      fetch_repository
    end

    context 'with existing repository' do
      it 'fetches repository from geo node' do
        subject.send(:ensure_repository)

        is_expected.to receive(:fetch_geo_mirror)

        fetch_repository
      end
    end

    context 'with a never synced repository' do
      it 'clones repository from geo node' do
        allow(repository).to receive(:exists?) { false }

        is_expected.to receive(:clone_geo_mirror)

        fetch_repository
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
