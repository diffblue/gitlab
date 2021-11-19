# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::FileDownloadDispatchWorker, :geo, :use_sql_query_cache_for_tracking_db do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let(:primary)   { create(:geo_node, :primary, host: 'primary-geo-node') }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)
    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:over_time?).and_return(false)
    end

    WebMock.stub_request(:get, /primary-geo-node/).to_return(status: 200, body: "", headers: {})

    allow(Geo::FileDownloadWorker).to receive(:with_status).and_return(Geo::FileDownloadWorker)
    stub_feature_flags(geo_job_artifact_replication: false)
  end

  it 'does not schedule anything when tracking database is not configured' do
    create(:lfs_object, :with_file)

    allow(Gitlab::Geo).to receive(:geo_database_configured?) { false }

    expect(Geo::FileDownloadWorker).not_to receive(:perform_async)

    subject.perform

    # We need to unstub here or the DatabaseCleaner will have issues since it
    # will appear as though the tracking DB were not available
    allow(Gitlab::Geo).to receive(:geo_database_configured?).and_call_original
  end

  it 'does not schedule anything when node is disabled' do
    create(:lfs_object, :with_file)

    secondary.enabled = false
    secondary.save!

    expect(Geo::FileDownloadWorker).not_to receive(:perform_async)

    subject.perform
  end

  context 'with job artifacts' do
    it 'performs Geo::FileDownloadWorker for unsynced job artifacts' do
      registry = create(:geo_job_artifact_registry_legacy, :with_artifact, :never_synced)

      expect(Geo::FileDownloadWorker).to receive(:perform_async)
        .with('job_artifact', registry.artifact_id).once.and_return(spy)

      subject.perform
    end

    it 'performs Geo::FileDownloadWorker for failed-sync job artifacts' do
      registry = create(:geo_job_artifact_registry_legacy, :with_artifact, :failed)

      expect(Geo::FileDownloadWorker).to receive(:perform_async)
        .with('job_artifact', registry.artifact_id).once.and_return(spy)

      subject.perform
    end

    it 'does not perform Geo::FileDownloadWorker for synced job artifacts' do
      registry = create(:geo_job_artifact_registry_legacy, :with_artifact, bytes: 1234, success: true)

      expect(Geo::FileDownloadWorker).not_to receive(:perform_async)
        .with('job_artifact', registry.artifact_id)

      subject.perform
    end

    it 'does not perform Geo::FileDownloadWorker for synced job artifacts even with 0 bytes downloaded' do
      registry = create(:geo_job_artifact_registry_legacy, :with_artifact, bytes: 0, success: true)

      expect(Geo::FileDownloadWorker).not_to receive(:perform_async)
        .with('job_artifact', registry.artifact_id)

      subject.perform
    end

    it 'does not retry failed artifacts when retry_at is tomorrow' do
      registry = create(:geo_job_artifact_registry_legacy, :with_artifact, :failed, retry_at: Date.tomorrow)

      expect(Geo::FileDownloadWorker).not_to receive(:perform_async)
       .with('job_artifact', registry.artifact_id)

      subject.perform
    end

    it 'retries failed artifacts when retry_at is in the past' do
      registry = create(:geo_job_artifact_registry_legacy, :with_artifact, :failed, retry_at: Date.yesterday)

      expect(Geo::FileDownloadWorker).to receive(:perform_async)
        .with('job_artifact', registry.artifact_id).once.and_return(spy)

      subject.perform
    end

    context 'with files missing on the primary that are marked as synced' do
      let!(:artifact_file_missing_on_primary) { create(:ci_job_artifact) }
      let!(:artifact_registry) { create(:geo_job_artifact_registry_legacy, artifact_id: artifact_file_missing_on_primary.id, bytes: 1234, success: true, missing_on_primary: true) }

      it 'retries the files if there is spare capacity' do
        registry = create(:geo_job_artifact_registry_legacy, :with_artifact, :never_synced)

        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', registry.artifact_id)
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact_file_missing_on_primary.id)

        subject.perform
      end

      it 'retries failed files with retry_at in the past' do
        artifact_registry.update!(retry_at: Date.yesterday)

        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', artifact_file_missing_on_primary.id)

        subject.perform
      end

      it 'does not retry files with later retry_at' do
        artifact_registry.update!(retry_at: Date.tomorrow)

        expect(Geo::FileDownloadWorker).not_to receive(:perform_async).with('job_artifact', artifact_file_missing_on_primary.id)

        subject.perform
      end

      it 'does not retry those files if there is no spare capacity' do
        registry = create(:geo_job_artifact_registry_legacy, :with_artifact, :never_synced)

        expect(subject).to receive(:db_retrieve_batch_size).and_return(1).twice
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', registry.artifact_id)

        subject.perform
      end

      it 'does not retry those files if they are already scheduled' do
        registry = create(:geo_job_artifact_registry_legacy, :with_artifact, :never_synced)

        scheduled_jobs = [{ type: 'job_artifact', id: artifact_file_missing_on_primary.id, job_id: 'foo' }]
        expect(subject).to receive(:scheduled_jobs).and_return(scheduled_jobs).at_least(1)
        expect(Geo::FileDownloadWorker).to receive(:perform_async).with('job_artifact', registry.artifact_id)

        subject.perform
      end
    end
  end

  context 'backoff time' do
    let(:cache_key) { "#{described_class.name.underscore}:skip" }

    it 'does not set the back off time when there are no pending items' do
      expect(Rails.cache).not_to receive(:write).with(cache_key, true, expires_in: 300.seconds)

      subject.perform
    end
  end

  # Test the case where we have:
  #
  # 1. A total of 10 files in the queue, and we can load a maximimum of 5 and send 2 at a time.
  # 2. We send 2, wait for 1 to finish, and then send again.
  it 'attempts to load a new batch without pending downloads' do
    stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 5)
    secondary.update!(files_max_capacity: 4)
    result_object = double(:result, success: true, bytes_downloaded: 100, primary_missing_file: false)
    allow_any_instance_of(::Gitlab::Geo::Replication::BaseTransfer).to receive(:download_from_primary).and_return(result_object)

    create_list(:geo_job_artifact_registry_legacy, 6, :with_artifact, :never_synced)

    expect(Geo::FileDownloadWorker).to receive(:perform_async).exactly(6).times.and_call_original
    # For 10 downloads, we expect four database reloads:
    # 1. Load the first batch of 5.
    # 2. 4 get sent out, 1 remains. This triggers another reload, which loads in the next 5.
    # 3. Those 4 get sent out, and 1 remains.
    # 3. Since the second reload filled the pipe with 4, we need to do a final reload to ensure
    #    zero are left.
    expect(subject).to receive(:load_pending_resources).exactly(3).times.and_call_original

    Sidekiq::Testing.inline! do
      subject.perform
    end
  end
end
