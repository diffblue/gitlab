# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticIndexBulkCronWorker, feature_category: :global_search do
  include ExclusiveLeaseHelpers

  let(:worker) { described_class.new }
  let(:lease_key) { 'elastic_index_bulk_cron_worker' }

  let(:shards) { [0, 1] }
  let(:shard_number) { shards.first }

  before do
    stub_const("Elastic::ProcessBookkeepingService::SHARDS", shards)
    stub_ee_application_setting(elasticsearch_indexing: true, elasticsearch_requeue_workers: true)
    allow(Search::ClusterHealthCheck::Elastic).to receive(:healthy?).and_return(true)
  end

  describe '.perform' do
    context 'indexing is not paused' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(false)
      end

      it 'queues all shards for execution' do
        shards.each do |shard_number|
          expect(described_class).to receive(:perform_async).with(shard_number)
        end

        worker.perform
      end

      context 'legacy lease is detected' do
        before do
          allow(Gitlab::ExclusiveLease).to receive(:get_uuid).with(lease_key).and_return('lease_uuid')
        end

        it 'skips scheduling' do
          expect(described_class).not_to receive(:perform_async)

          worker.perform
        end

        it 'skips shard execution' do
          expect(described_class).not_to receive(:perform_async)

          worker.perform(shard_number)
        end
      end

      it 'executes the service under an exclusive lease' do
        expect_to_obtain_exclusive_lease("#{lease_key}/shard/#{shard_number}")

        expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
          expect(service).to receive(:execute).with(shards: [shard_number])
        end

        worker.perform(shard_number)
      end

      context 'when search cluster is unhealthy' do
        before do
          allow(Search::ClusterHealthCheck::Elastic).to receive(:healthy?).and_return(false)
        end

        it 'does nothing if cluster is not healthy' do
          expect(::Elastic::ProcessBookkeepingService).not_to receive(:new)

          expect(worker.perform).to eq(false)
        end
      end
    end

    context 'indexing is paused' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(true)
      end

      it 'does nothing if indexing is paused' do
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:new)

        expect(worker.perform).to eq(false)
      end
    end

    context 'when indexing is disabled' do
      before do
        stub_ee_application_setting(elasticsearch_indexing: false)
      end

      it 'does nothing if indexing is disabled' do
        expect(::Elastic::ProcessBookkeepingService).not_to receive(:new)

        expect(worker.perform).to eq(false)
        expect(described_class).not_to receive(:perform_async)
      end
    end

    context 'when service returns non-zero counter' do
      before do
        expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
          expect(service).to receive(:execute).and_return([15, 0])
        end
      end

      it 'adds logging_extras to the done log' do
        worker.perform(shard_number)

        expect(worker.logging_extras).to eq(
          "#{ApplicationWorker::LOGGING_EXTRA_KEY}.elastic_index_bulk_cron_worker.records_count" => 15,
          "#{ApplicationWorker::LOGGING_EXTRA_KEY}.elastic_index_bulk_cron_worker.shard_number" => shard_number
        )
      end

      it 'requeues the worker' do
        expect(described_class).to receive(:perform_in).with(described_class::RESCHEDULE_INTERVAL, shard_number)

        worker.perform(shard_number)
      end

      context 'when requeue is disabled' do
        before do
          stub_ee_application_setting(elasticsearch_requeue_workers: false)
        end

        it 'does not requeues the worker' do
          expect(described_class).not_to receive(:perform_in).with(described_class::RESCHEDULE_INTERVAL, shard_number)

          worker.perform(shard_number)
        end
      end
    end

    context 'when there are no records in the queue' do
      it 'does not requeue the worker' do
        expect(described_class).not_to receive(:perform_in)

        worker.perform(shard_number)
      end
    end

    context 'when indexing failures occur in the queue' do
      before do
        expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
          expect(service).to receive(:execute).and_return([15, 5])
        end
      end

      it 'does not requeue the worker' do
        expect(described_class).not_to receive(:perform_in)

        worker.perform(shard_number)
      end
    end
  end

  it_behaves_like 'worker with data consistency', described_class, data_consistency: :sticky
  it_behaves_like 'an idempotent worker' do
    before do
      allow(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(false)
    end

    context 'when executed without arguments' do
      it 'queues all shards for execution' do
        shards.each do |shard_number|
          expect(described_class).to receive(:perform_async).with(shard_number)
        end

        worker.perform
      end
    end

    context 'when executed with a shard number argument' do
      let(:job_args) { shards.first }

      it 'executes the service under an exclusive lease' do
        expect_to_obtain_exclusive_lease("#{lease_key}/shard/#{job_args}")

        expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
          expect(service).to receive(:execute).with(shards: [job_args])
        end

        worker.perform(job_args)
      end
    end
  end
end
