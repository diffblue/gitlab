# frozen_string_literal: true

# Include these shared examples in BlobReplicatorStrategy,
# RepositoryReplicatorStrategy, etc.
#
# Required let variables:
#
#   - `replicator` should be an instance of the Replicator class being tested, e.g. PackageFileReplicator
#   - 'event_name' should be the event_name to enqueue a replicable synchronization
#   - `model_record` should be a valid instance of the model class. It may be unpersisted.
#   - `primary` should be the primary GeoNode
#   - `secondary` should be a secondary GeoNode
#
RSpec.shared_examples 'a replicator' do
  include EE::GeoHelpers

  context 'Geo node status' do
    context 'on a primary site' do
      let_it_be(:model_class_factory) { model_class_factory_name(described_class.registry_class) }
      let_it_be(:replicables) { create_list(model_class_factory, 2) }

      describe '.primary_total_count' do
        context 'when batch count feature flag is enabled' do
          before do
            # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
            # is not allowed within a transaction but all RSpec tests run inside of a transaction.
            stub_batch_counter_transaction_open_check
          end

          it 'returns the number of available replicables on primary' do
            expect(described_class.primary_total_count).to eq(2)
          end
        end

        context 'when batch count feature flag is disabled' do
          before do
            stub_feature_flags(geo_batch_count: false)
          end

          it 'returns the number of available replicables on primary' do
            expect(described_class.primary_total_count).to eq(2)
          end
        end
      end
    end

    context 'on a secondary site' do
      let_it_be(:registry_factory) { registry_factory_name(described_class.registry_class) }

      before do
        create(registry_factory, :synced)
        create(registry_factory) # rubocop: disable Rails/SaveBang
        create(registry_factory, :failed)
      end

      describe '.registry_count' do
        context 'when batch count feature flag is enabled' do
          before do
            # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
            # is not allowed within a transaction but all RSpec tests run inside of a transaction.
            stub_batch_counter_transaction_open_check
          end

          it 'returns the number of registries on secondary' do
            expect(described_class.registry_count).to eq(3)
          end
        end

        context 'when batch count feature flag is disabled' do
          before do
            stub_feature_flags(geo_batch_count: false)
          end

          it 'returns the number of registries on secondary' do
            expect(described_class.registry_count).to eq(3)
          end
        end
      end

      describe '.synced_count' do
        context 'when batch count feature flag is enabled' do
          before do
            # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
            # is not allowed within a transaction but all RSpec tests run inside of a transaction.
            stub_batch_counter_transaction_open_check
          end

          it 'returns the number of synced items on secondary' do
            expect(described_class.synced_count).to eq(1)
          end
        end

        context 'when batch count feature flag is disabled' do
          before do
            stub_feature_flags(geo_batch_count: false)
          end

          it 'returns the number of synced items on secondary' do
            expect(described_class.synced_count).to eq(1)
          end
        end
      end

      describe '.failed_count' do
        context 'when batch count feature flag is enabled' do
          before do
            # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
            # is not allowed within a transaction but all RSpec tests run inside of a transaction.
            stub_batch_counter_transaction_open_check
          end

          it 'returns the number of failed items on secondary' do
            expect(described_class.failed_count).to eq(1)
          end
        end

        context 'when batch count feature flag is disabled' do
          before do
            stub_feature_flags(geo_batch_count: false)
          end

          it 'returns the number of failed items on secondary' do
            expect(described_class.failed_count).to eq(1)
          end
        end
      end
    end
  end

  context 'when replicator is Geo::RegistrySyncWorker compatible' do
    it 'has "created" and "deleted" events' do
      expect(described_class).to be_event_supported(:created)
      expect(described_class).to be_event_supported(:deleted)
    end
  end

  context 'when replicator enqueues a sync event' do
    specify do
      expect(Geo::EventWorker).to receive(:perform_async).with(
        replicator.replicable_name,
        event_name,
        { model_record_id: model_record.id }
      )

      replicator.enqueue_sync
    end
  end
end
