# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::RegistrySyncWorker, :geo, :use_sql_query_cache_for_tracking_db do
  include ::EE::GeoHelpers
  include ExclusiveLeaseHelpers

  let(:primary)   { create(:geo_node, :primary) }
  let(:secondary) { create(:geo_node) }

  before do
    stub_current_geo_node(secondary)
    stub_exclusive_lease(renew: true)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:over_time?).and_return(false)
    end

    allow(::Geo::EventWorker).to receive(:with_status).and_return(::Geo::EventWorker)

    stub_feature_flags(geo_container_repository_replication: false)
  end

  it 'does not schedule anything when tracking database is not configured' do
    create(:geo_package_file_registry)

    expect(::Geo::EventWorker).not_to receive(:perform_async)

    with_no_geo_database_configured do
      subject.perform
    end
  end

  it 'does not schedule anything when node is disabled' do
    create(:geo_package_file_registry)

    secondary.enabled = false
    secondary.save!

    expect(::Geo::EventWorker).not_to receive(:perform_async)

    subject.perform
  end

  it 'does not schedule duplicated jobs' do
    package_file_1 = create(:geo_package_file_registry)
    package_file_2 = create(:geo_package_file_registry)

    stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 5)
    secondary.update!(files_max_capacity: 2)
    allow(Gitlab::SidekiqStatus).to receive(:job_status).with([]).and_return([]).twice
    allow(Gitlab::SidekiqStatus).to receive(:job_status).with(array_including('123', '456')).and_return([true, true], [true, true], [false, false])

    expect(::Geo::EventWorker)
      .to receive(:perform_async)
      .with('package_file', :created, { model_record_id: package_file_1.package_file.id })
      .once
      .and_return('123')
    expect(::Geo::EventWorker)
      .to receive(:perform_async)
      .with('package_file', :created, { model_record_id: package_file_2.package_file.id })
      .once
      .and_return('456')

    subject.perform
  end

  it 'does not schedule duplicated jobs because of query cache' do
    package_file_1 = create(:geo_package_file_registry)
    package_file_2 = create(:geo_package_file_registry)

    # We retrieve all the items in a single batch
    stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 2)
    secondary.update!(files_max_capacity: 2)

    expect(Geo::EventWorker).to receive(:perform_async).with('package_file', :created, { model_record_id: package_file_1.package_file.id }).once do
      Thread.new do
        # Rails will invalidate the query cache if the update happens in the same thread
        Geo::PackageFileRegistry.update(state: Geo::PackageFileRegistry::STATE_VALUES[:synced]) # rubocop:disable Rails/SaveBang
      end
    end

    expect(Geo::EventWorker).to receive(:perform_async)
                                  .with('package_file', :created, { model_record_id: package_file_2.package_file.id })
                                  .once

    subject.perform
  end

  # Test the case where we have:
  #
  # 1. A total of 10 files in the queue, and we can load a maximimum of 5 and send 2 at a time.
  # 2. We send 2, wait for 1 to finish, and then send again.
  it 'attempts to load a new batch without pending downloads' do
    stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 5)
    secondary.update!(files_max_capacity: 2)

    result_object = double(
      :result,
      success: true,
      bytes_downloaded: 100,
      primary_missing_file: false,
      reason: '',
      extra_details: {}
    )

    allow_any_instance_of(::Gitlab::Geo::Replication::BlobDownloader).to receive(:execute).and_return(result_object)

    create_list(:geo_package_file_registry, 10)

    expect(::Geo::EventWorker).to receive(:perform_async).exactly(10).times.and_call_original
    # For 10 downloads, we expect four database reloads:
    # 1. Load the first batch of 5.
    # 2. 4 get sent out, 1 remains. This triggers another reload, which loads in the next 5.
    # 3. Those 4 get sent out, and 1 remains.
    # 4. Since the second reload filled the pipe with 4, we need to do a final reload to ensure
    #    zero are left.
    expect(subject).to receive(:load_pending_resources).exactly(4).times.and_call_original

    Sidekiq::Testing.inline! do
      subject.perform
    end
  end

  describe '.max_capacity' do
    before do
      secondary.update!(files_max_capacity: 6, container_repositories_max_capacity: 3)
    end

    context 'when geo_container_repository_replication is enabled' do
      before do
        stub_feature_flags(geo_container_repository_replication: true)
      end

      it 'returns the capacity based on files_max_capacity and container_repositories_max_capacity' do
        expect(described_class.new.send(:max_capacity)).to eq(9)
      end
    end

    context 'when geo_container_repository_replication is disabled' do
      it 'returns only files_max_capacity based capacity' do
        expect(described_class.new.send(:max_capacity)).to eq(6)
      end
    end
  end
end
