# frozen_string_literal: true

RSpec.shared_examples 'a framework registry sync worker' do |registry_factory, sync_concurrency_limit|
  describe '#perform', :use_sql_query_cache_for_tracking_db do
    include ExclusiveLeaseHelpers

    let!(:primary) { create(:geo_node, :primary) }
    let(:secondary) { create(:geo_node) }

    before do
      stub_current_geo_node(secondary)
      stub_exclusive_lease(renew: true)

      allow_next_instance_of(described_class) do |instance|
        allow(instance).to receive(:over_time?).and_return(false)
      end

      allow(::Geo::EventWorker).to receive(:with_status).and_return(::Geo::EventWorker)
    end

    it 'does not schedule anything when tracking database is not configured' do
      # rubocop:disable Rails/SaveBang
      create(registry_factory)
      # rubocop:enable Rails/SaveBang

      expect(::Geo::EventWorker).not_to receive(:perform_async)

      with_no_geo_database_configured do
        subject.perform
      end
    end

    it 'does not schedule anything when node is disabled' do
      # rubocop:disable Rails/SaveBang
      create(registry_factory)
      # rubocop:enable Rails/SaveBang

      secondary.enabled = false
      secondary.save!

      expect(::Geo::EventWorker).not_to receive(:perform_async)

      subject.perform
    end

    it 'does not schedule duplicated jobs' do
      # rubocop:disable Rails/SaveBang
      registry_1 = create(registry_factory)
      registry_2 = create(registry_factory)
      # rubocop:enable Rails/SaveBang

      stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 5)
      update_sync_concurrent_limit(secondary, sync_concurrency_limit)

      allow(Gitlab::SidekiqStatus)
        .to receive(:job_status)
        .with([])
        .and_return([])
        .twice

      allow(Gitlab::SidekiqStatus)
        .to receive(:job_status)
        .with(array_including('123', '456'))
        .and_return([true, true], [true, true], [false, false])

      expect(::Geo::EventWorker)
        .to receive(:perform_async)
        .with(registry_1.replicator.replicable_name, :created, { model_record_id: registry_1.model_record_id })
        .once
        .and_return('123')

      expect(::Geo::EventWorker)
        .to receive(:perform_async)
        .with(registry_2.replicator.replicable_name, :created, { model_record_id: registry_2.model_record_id })
        .once
        .and_return('456')

      subject.perform
    end

    it 'does not schedule duplicated jobs because of query cache' do
      # rubocop:disable Rails/SaveBang
      registry_1 = create(registry_factory)
      registry_2 = create(registry_factory)
      # rubocop:enable Rails/SaveBang

      # We retrieve all the items in a single batch
      stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 2)
      update_sync_concurrent_limit(secondary, sync_concurrency_limit)

      expect(Geo::EventWorker)
        .to receive(:perform_async)
        .with(registry_1.replicator.replicable_name, :created, { model_record_id: registry_1.model_record_id })
        .once do
          Thread.new do
            # Rails will invalidate the query cache if the update happens in the same thread
            # rubocop:disable Rails/SaveBang
            registry_1.class.update(state: registry_1.class::STATE_VALUES[:synced])
            # rubocop:enable Rails/SaveBang
          end
        end

      expect(Geo::EventWorker)
        .to receive(:perform_async)
        .with(registry_2.replicator.replicable_name, :created, { model_record_id: registry_2.model_record_id })
        .once

      subject.perform
    end

    # Test the case where we have:
    #
    # 1. A total of 10 registries in the queue, and we can load a maximimum of 5 and send 2 at a time.
    # 2. We send 2, wait for 1 to finish, and then send again.
    it 'attempts to load a new batch without pending registries' do
      stub_const('Geo::Scheduler::SchedulerWorker::DB_RETRIEVE_BATCH_SIZE', 5)
      update_sync_concurrent_limit(secondary, sync_concurrency_limit)

      create_list(registry_factory, 10)

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

    # TODO: Group wikis and snippet repositories sync at 1/10 of max capacity.
    #       Remove/adjust this based on the feature flags which control project/wiki
    #       migration to SSF at https://gitlab.com/groups/gitlab-org/-/epics/4623.
    def update_sync_concurrent_limit(secondary, sync_concurrency_limit)
      sync_concurrency_limit_value =
        if sync_concurrency_limit == :repos_max_capacity
          20
        else
          2
        end

      secondary.update!(sync_concurrency_limit => sync_concurrency_limit_value)
    end
  end
end
