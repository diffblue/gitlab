# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ElasticIndexBulkCronWorker do
  include ExclusiveLeaseHelpers
  describe '.perform' do
    let(:worker) { described_class.new }

    context 'indexing is not paused' do
      before do
        expect(Elastic::IndexingControl).to receive(:non_cached_pause_indexing?).and_return(false)
      end

      it 'executes the service under an exclusive lease' do
        expect_to_obtain_exclusive_lease('elastic_index_bulk_cron_worker')

        expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
          expect(service).to receive(:execute)
        end

        worker.perform
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

    context 'when service returns non-zero counter' do
      before do
        expect_next_instance_of(::Elastic::ProcessBookkeepingService) do |service|
          expect(service).to receive(:execute).and_return(15)
        end
      end

      it 'adds the elastic_bulk_count to the done log' do
        worker.perform

        expect(worker.logging_extras).to eq(
          "#{ApplicationWorker::LOGGING_EXTRA_KEY}.elastic_index_bulk_cron_worker.records_count" => 15
        )
      end

      it 'requeues the worker' do
        expect(described_class).to receive(:perform_in)

        worker.perform
      end

      it 'does not requeue the worker if FF is disabled' do
        stub_feature_flags(bulk_cron_worker_auto_requeue: false)
        expect(described_class).not_to receive(:perform_in)

        worker.perform
      end
    end

    context 'when there are no records in the queue' do
      it 'does not requeue the worker' do
        expect(described_class).not_to receive(:perform_in)

        worker.perform
      end
    end
  end

  it_behaves_like 'worker with data consistency',
                  described_class,
                  data_consistency: :sticky
end
