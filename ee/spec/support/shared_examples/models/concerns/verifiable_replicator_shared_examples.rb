# frozen_string_literal: true

# This should be included on any Replicator which implements verification.
#
# Expected let variables:
#
# - primary
# - secondary
# - model_record
# - replicator
#
RSpec.shared_examples 'a verifiable replicator' do
  include EE::GeoHelpers

  describe 'events' do
    it 'has checksum_succeeded event' do
      expect(described_class.supported_events).to include(:checksum_succeeded)
    end
  end

  describe '.verification_enabled?' do
    context 'when replication is enabled' do
      before do
        expect(described_class).to receive(:enabled?).and_return(true)
      end

      context 'when verification_feature_flag_enabled? returns true' do
        it 'returns true' do
          allow(described_class).to receive(:verification_feature_flag_enabled?).and_return(true)

          expect(described_class.verification_enabled?).to be_truthy
        end
      end

      context 'when verification_feature_flag_enabled? returns false' do
        it 'returns false' do
          allow(described_class).to receive(:verification_feature_flag_enabled?).and_return(false)

          expect(described_class.verification_enabled?).to be_falsey
        end
      end
    end

    context 'when replication is disabled' do
      before do
        expect(described_class).to receive(:enabled?).and_return(false)
      end

      it 'returns false' do
        expect(described_class.verification_enabled?).to be_falsey
      end
    end
  end

  RSpec.shared_examples 'a counter of succeeded available verifiables' do |count_method|
    specify do
      verifiable.verification_started!
      verifiable.verification_succeeded_with_checksum!('some checksum', Time.current)

      expect(described_class.send(count_method)).to eq(1)
    end

    it 'excludes other verification states' do
      verifiable.verification_started!

      expect(described_class.send(count_method)).to eq(0)

      verifiable.verification_failed_with_message!('some error message')

      expect(described_class.send(count_method)).to eq(0)

      verifiable.verification_pending!

      expect(described_class.send(count_method)).to eq(0)
    end
  end

  describe '.checksummed_count' do
    context 'when verification is enabled' do
      let(:verifiable) { model_record }

      before do
        allow(described_class).to receive(:verification_enabled?).and_return(true)
      end

      context 'when batch count feature flag is enabled' do
        before do
          # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
          # is not allowed within a transaction but all RSpec tests run inside of a transaction.
          stub_batch_counter_transaction_open_check
        end

        it_behaves_like 'a counter of succeeded available verifiables', :checksummed_count
      end

      context 'when batch count feature flag is disabled' do
        before do
          stub_feature_flags(geo_batch_count: false)
        end

        it_behaves_like 'a counter of succeeded available verifiables', :checksummed_count
      end
    end

    context 'when verification is disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:verification_enabled?).and_return(false)

        expect(described_class.checksummed_count).to be_nil
      end
    end
  end

  describe '.verified_count' do
    context 'when verification is enabled' do
      let(:verifiable) { replicator.registry }

      before do
        model_record.save!

        allow(described_class).to receive(:verification_enabled?).and_return(true)

        # Verification on the secondary requires a synced registry
        verifiable.start
        verifiable.synced!
      end

      context 'when batch count feature flag is enabled' do
        before do
          # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
          # is not allowed within a transaction but all RSpec tests run inside of a transaction.
          stub_batch_counter_transaction_open_check
        end

        it_behaves_like 'a counter of succeeded available verifiables', :verified_count
      end

      context 'when batch count feature flag is disabled' do
        before do
          stub_feature_flags(geo_batch_count: false)
        end

        it_behaves_like 'a counter of succeeded available verifiables', :verified_count
      end
    end

    context 'when verification is disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:verification_enabled?).and_return(false)

        expect(described_class.verified_count).to be_nil
      end
    end
  end

  RSpec.shared_examples 'a counter of failed available verifiables' do |count_method|
    specify do
      verifiable.verification_started!
      verifiable.verification_failed_with_message!('some error message')

      # This bypasses the registry state attribute to :synced again
      # since available_verifiables return synced registries
      # and we need that state to count it properly.
      verifiable.update_attribute(:state, 2) if count_method == :verification_failed_count

      expect(described_class.send(count_method)).to eq(1)
    end

    it 'excludes other verification states' do
      verifiable.verification_started!

      expect(described_class.send(count_method)).to eq(0)

      verifiable.verification_succeeded_with_checksum!('foo', Time.current)

      expect(described_class.send(count_method)).to eq(0)

      verifiable.verification_pending!

      expect(described_class.send(count_method)).to eq(0)
    end
  end

  describe '.checksum_failed_count' do
    context 'when verification is enabled' do
      let(:verifiable) { model_record }

      context 'when batch count feature flag is enabled' do
        before do
          # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
          # is not allowed within a transaction but all RSpec tests run inside of a transaction.
          stub_batch_counter_transaction_open_check
        end

        it_behaves_like 'a counter of failed available verifiables', :checksum_failed_count
      end

      context 'when batch count feature flag is disabled' do
        before do
          stub_feature_flags(geo_batch_count: false)
        end

        it_behaves_like 'a counter of failed available verifiables', :checksum_failed_count
      end
    end

    context 'when verification is disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:verification_enabled?).and_return(false)

        expect(described_class.checksum_failed_count).to be_nil
      end
    end
  end

  describe '.verification_failed_count' do
    context 'when verification is enabled' do
      let(:verifiable) { replicator.registry }

      before do
        model_record.save!

        allow(described_class).to receive(:verification_enabled?).and_return(true)

        # Verification on the secondary requires a synced registry
        verifiable.start
        verifiable.synced!
      end

      context 'when batch count feature flag is enabled' do
        before do
          # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
          # is not allowed within a transaction but all RSpec tests run inside of a transaction.
          stub_batch_counter_transaction_open_check
        end

        it_behaves_like 'a counter of failed available verifiables', :verification_failed_count
      end

      context 'when batch count feature flag is disabled' do
        before do
          stub_feature_flags(geo_batch_count: false)
        end

        it_behaves_like 'a counter of failed available verifiables', :verification_failed_count
      end
    end

    context 'when verification is disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:verification_enabled?).and_return(false)

        expect(described_class.verification_failed_count).to be_nil
      end
    end
  end

  describe '.verification_total_count' do
    context 'when verification is enabled' do
      let(:verifiable) { replicator.registry }

      before do
        model_record.save!

        allow(described_class).to receive(:verification_enabled?).and_return(true)

        # Verification on the secondary requires a synced registry
        verifiable.start
        verifiable.synced!
      end

      context 'when batch count feature flag is enabled' do
        before do
          # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
          # is not allowed within a transaction but all RSpec tests run inside of a transaction.
          stub_batch_counter_transaction_open_check
        end

        context 'when the verification_state is disabled' do
          specify do
            verifiable.verification_disabled!

            expect(described_class.verification_total_count).to eq(0)
          end
        end

        context 'when the verification_state is not disabled' do
          specify do
            verifiable.verification_started!

            expect(described_class.verification_total_count).to eq(1)
          end
        end
      end

      context 'when batch count feature flag is disabled' do
        before do
          stub_feature_flags(geo_batch_count: false)
        end

        context 'when the verification_state is disabled' do
          specify do
            verifiable.verification_disabled!

            expect(described_class.verification_total_count).to eq(0)
          end
        end

        context 'when the verification_state is not disabled' do
          specify do
            verifiable.verification_started!

            expect(described_class.verification_total_count).to eq(1)
          end
        end
      end
    end

    context 'when verification is disabled' do
      it 'returns nil' do
        allow(described_class).to receive(:verification_enabled?).and_return(false)

        expect(described_class.verification_total_count).to be_nil
      end
    end
  end

  describe '.trigger_background_verification' do
    context 'when verification is enabled' do
      before do
        allow(described_class).to receive(:verification_enabled?).and_return(true)
      end

      shared_examples 'enqueues verification workers' do
        it 'enqueues VerificationBatchWorker' do
          expect(::Geo::VerificationBatchWorker).to receive(:perform_with_capacity).with(described_class.replicable_name)

          described_class.trigger_background_verification
        end

        it 'enqueues VerificationTimeoutWorker' do
          expect(::Geo::VerificationTimeoutWorker).to receive(:perform_async).with(described_class.replicable_name)

          described_class.trigger_background_verification
        end
      end

      context 'for a Geo secondary' do
        before do
          stub_current_geo_node(secondary)
        end

        it 'does not enqueue ReverificationBatchWorker' do
          expect(::Geo::ReverificationBatchWorker).not_to receive(:perform_with_capacity)

          described_class.trigger_background_verification
        end

        include_examples 'enqueues verification workers'
      end

      context 'for a Geo primary' do
        before do
          stub_current_geo_node(primary)
        end

        it 'enqueues ReverificationBatchWorker' do
          expect(::Geo::ReverificationBatchWorker).to receive(:perform_with_capacity).with(described_class.replicable_name)

          described_class.trigger_background_verification
        end

        it 'enqueues VerificationStateBackfillWorker' do
          expect(described_class.model).to receive(:separate_verification_state_table?).and_return(true)
          expect(::Geo::VerificationStateBackfillWorker).to receive(:perform_async).with(described_class.replicable_name)

          described_class.trigger_background_verification
        end

        include_examples 'enqueues verification workers'
      end
    end

    context 'when verification is disabled' do
      before do
        allow(described_class).to receive(:verification_enabled?).and_return(false)
      end

      it 'does not enqueue VerificationBatchWorker' do
        expect(::Geo::VerificationBatchWorker).not_to receive(:perform_with_capacity)

        described_class.trigger_background_verification
      end

      it 'does not enqueue VerificationTimeoutWorker' do
        expect(::Geo::VerificationTimeoutWorker).not_to receive(:perform_async)

        described_class.trigger_background_verification
      end
    end
  end

  describe '.backfill_verification_state_table' do
    context 'when on secondary' do
      before do
        stub_secondary_node
      end

      it 'returns false' do
        expect(described_class.backfill_verification_state_table).to be_falsy
      end
    end

    it 'calls VerificationStateBackfillService' do
      stub_primary_node

      expect_next_instance_of(Geo::VerificationStateBackfillService) do |service|
        expect(service).to receive(:execute).and_return(true)
      end

      described_class.backfill_verification_state_table
    end
  end

  describe '.verify_batch' do
    context 'when there are records needing verification' do
      let(:another_replicator) { double('another_replicator', verify: true) }
      let(:replicators) { [replicator, another_replicator] }

      before do
        allow(described_class).to receive(:replicator_batch_to_verify).and_return(replicators)
      end

      it 'calls #verify on each replicator' do
        expect(replicator).to receive(:verify)
        expect(another_replicator).to receive(:verify)

        described_class.verify_batch
      end
    end
  end

  describe '.remaining_verification_batch_count' do
    it 'converts needs_verification_count to number of batches' do
      expected_limit = 40
      expect(described_class).to receive(:needs_verification_count).with(limit: expected_limit).and_return(21)

      expect(described_class.remaining_verification_batch_count(max_batch_count: 4)).to eq(3)
    end
  end

  describe '.remaining_reverification_batch_count' do
    it 'converts needs_reverification_count to number of batches' do
      expected_limit = 4000
      expect(described_class).to receive(:needs_reverification_count).with(limit: expected_limit).and_return(1500)

      expect(described_class.remaining_reverification_batch_count(max_batch_count: 4)).to eq(2)
    end
  end

  describe '.reverify_batch!' do
    it 'calls #reverify_batch' do
      allow(described_class).to receive(:reverify_batch).with(batch_size: described_class::DEFAULT_REVERIFICATION_BATCH_SIZE)

      described_class.reverify_batch!
    end
  end

  describe '.replicator_batch_to_verify' do
    it 'returns usable Replicator instances' do
      model_record.save!

      expect(described_class).to receive(:model_record_id_batch_to_verify).and_return([model_record.id])

      first_result = described_class.replicator_batch_to_verify.first

      expect(first_result.class).to eq(described_class)
      expect(first_result.model_record_id).to eq(model_record.id)
    end
  end

  describe '.model_record_id_batch_to_verify' do
    let(:pending_ids) { [1, 2] }

    before do
      allow(described_class).to receive(:verification_batch_size).and_return(verification_batch_size)
      allow(described_class).to receive(:verification_pending_batch).with(batch_size: verification_batch_size).and_return(pending_ids)
    end

    context 'when the batch is filled by pending rows' do
      let(:verification_batch_size) { 2 }

      it 'returns IDs of pending rows' do
        expect(described_class.model_record_id_batch_to_verify).to eq(pending_ids)
      end

      it 'does not call .verification_failed_batch' do
        expect(described_class).not_to receive(:verification_failed_batch)

        described_class.model_record_id_batch_to_verify
      end
    end

    context 'when that batch is not filled by pending rows' do
      let(:failed_ids) { [3, 4, 5] }
      let(:verification_batch_size) { 5 }

      it 'includes IDs of failed rows' do
        remaining_capacity = verification_batch_size - pending_ids.size

        allow(described_class).to receive(:verification_failed_batch).with(batch_size: remaining_capacity).and_return(failed_ids)

        result = described_class.model_record_id_batch_to_verify

        expect(result).to include(*pending_ids)
        expect(result).to include(*failed_ids)
      end
    end
  end

  describe '.verification_pending_batch' do
    context 'when current node is a primary' do
      it 'delegates to the model class of the replicator' do
        expect(described_class.model).to receive(:verification_pending_batch)

        described_class.verification_pending_batch
      end
    end

    context 'when current node is a secondary' do
      it 'delegates to the registry class of the replicator' do
        stub_current_geo_node(secondary)

        expect(described_class.registry_class).to receive(:verification_pending_batch)

        described_class.verification_pending_batch
      end
    end
  end

  describe '.verification_failed_batch' do
    context 'when current node is a primary' do
      it 'delegates to the model class of the replicator' do
        expect(described_class.model).to receive(:verification_failed_batch)

        described_class.verification_failed_batch
      end
    end

    context 'when current node is a secondary' do
      it 'delegates to the registry class of the replicator' do
        stub_current_geo_node(secondary)

        expect(described_class.registry_class).to receive(:verification_failed_batch)

        described_class.verification_failed_batch
      end
    end
  end

  describe '.fail_verification_timeouts' do
    context 'when current node is a primary' do
      it 'delegates to the model class of the replicator' do
        expect(described_class.model).to receive(:fail_verification_timeouts)

        described_class.fail_verification_timeouts
      end
    end

    context 'when current node is a secondary' do
      it 'delegates to the registry class of the replicator' do
        stub_current_geo_node(secondary)

        expect(described_class.registry_class).to receive(:fail_verification_timeouts)

        described_class.fail_verification_timeouts
      end
    end
  end

  describe '#after_verifiable_update' do
    using RSpec::Parameterized::TableSyntax

    where(:verification_enabled, :immutable, :checksum, :checksummable, :expect_verify_async) do
      true  | true  | nil      | true  | true
      true  | true  | nil      | false | false
      true  | true  | 'abc123' | true  | false
      true  | true  | 'abc123' | false | false
      true  | false | nil      | true  | true
      true  | false | nil      | false | false
      true  | false | 'abc123' | true  | true
      true  | false | 'abc123' | false | false
      false | true  | nil      | true  | false
      false | true  | nil      | false | false
      false | true  | 'abc123' | true  | false
      false | true  | 'abc123' | false | false
      false | false | nil      | true  | false
      false | false | nil      | false | false
      false | false | 'abc123' | true  | false
      false | false | 'abc123' | false | false
    end

    with_them do
      before do
        allow(described_class).to receive(:verification_enabled?).and_return(verification_enabled)
        allow(replicator).to receive(:immutable?).and_return(immutable)
        allow(replicator).to receive(:primary_checksum).and_return(checksum)
        allow(replicator).to receive(:checksummable?).and_return(checksummable)
      end

      it 'calls verify_async only if needed' do
        if expect_verify_async
          expect(replicator).to receive(:verify_async)
        else
          expect(replicator).not_to receive(:verify_async)
        end

        replicator.after_verifiable_update
      end
    end
  end

  describe '#verify_async' do
    before do
      model_record.save!
    end

    context 'on a Geo primary' do
      before do
        stub_primary_node
      end

      it 'calls verification_started! and enqueues VerificationWorker' do
        expect(model_record).to receive(:verification_started!)
        expect(Geo::VerificationWorker).to receive(:perform_async).with(replicator.replicable_name, model_record.id)

        replicator.verify_async
      end
    end
  end

  describe '#verify' do
    it 'wraps the checksum calculation in track_checksum_attempt!' do
      tracker = double('tracker')
      allow(replicator).to receive(:verification_state_tracker).and_return(tracker)
      allow(replicator).to receive(:calculate_checksum).and_return('abc123')

      expect(tracker).to receive(:track_checksum_attempt!).and_yield

      replicator.verify
    end
  end

  describe '#verification_state_tracker' do
    context 'on a Geo primary' do
      before do
        stub_primary_node
      end

      it 'returns model_record' do
        expect(replicator.verification_state_tracker).to eq(model_record)
      end
    end

    context 'on a Geo secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'returns registry' do
        registry = double('registry')
        allow(replicator).to receive(:registry).and_return(registry)

        expect(replicator.verification_state_tracker).to eq(registry)
      end
    end
  end

  describe '#handle_after_checksum_succeeded' do
    context 'on a Geo primary' do
      before do
        stub_primary_node
      end

      it 'creates checksum_succeeded event' do
        model_record

        expect { replicator.handle_after_checksum_succeeded }.to change { ::Geo::Event.count }.by(1)
        expect(::Geo::Event.last.event_name).to eq 'checksum_succeeded'
      end

      it 'is called on verification success' do
        model_record.verification_started

        expect { model_record.verification_succeeded_with_checksum!('abc123', Time.current) }.to change { ::Geo::Event.count }.by(1)
        expect(::Geo::Event.last.event_name).to eq 'checksum_succeeded'
      end
    end

    context 'on a Geo secondary' do
      before do
        stub_current_geo_node(secondary)
      end

      it 'does not create an event' do
        expect { replicator.handle_after_checksum_succeeded }.not_to change { ::Geo::Event.count }
      end
    end
  end

  describe '#consume_event_checksum_succeeded' do
    context 'with a persisted model_record' do
      before do
        model_record.save!
      end

      context 'on a Geo primary' do
        before do
          stub_primary_node
        end

        it 'does nothing' do
          expect(replicator).not_to receive(:registry)

          replicator.consume_event_checksum_succeeded
        end
      end

      context 'on a Geo secondary' do
        before do
          stub_current_geo_node(secondary)
        end

        context 'with a persisted registry' do
          let(:registry) { replicator.registry }

          before do
            registry.save!
          end

          context 'with a registry which is verified' do
            it 'sets state to verification_pending' do
              registry.verification_started
              registry.verification_succeeded_with_checksum!('foo', Time.current)

              expect do
                replicator.consume_event_checksum_succeeded
              end.to change { registry.reload.verification_state }
                .from(verification_state_value(:verification_succeeded))
                .to(verification_state_value(:verification_pending))
            end
          end

          context 'with a registry which is pending verification' do
            it 'does not change state from verification_pending' do
              registry.save!

              expect do
                replicator.consume_event_checksum_succeeded
              end.not_to change { registry.reload.verification_state }
                .from(verification_state_value(:verification_pending))
            end
          end
        end

        context 'with an unpersisted registry' do
          it 'does not persist the registry' do
            replicator.consume_event_checksum_succeeded

            expect(replicator.registry.persisted?).to be_falsey
          end
        end
      end
    end
  end

  describe '#primary_verification_succeeded?' do
    context 'when the model record is verification_succeeded' do
      it 'returns true' do
        allow(model_record).to receive(:verification_succeeded?).and_return(true)

        expect(replicator.primary_verification_succeeded?).to be_truthy
      end
    end

    context 'when the model record is verification_succeeded' do
      it 'returns false' do
        allow(model_record).to receive(:verification_succeeded?).and_return(false)

        expect(replicator.primary_verification_succeeded?).to be_falsey
      end
    end
  end

  context 'integration tests' do
    before do
      model_record.save!
    end

    context 'on a primary' do
      before do
        stub_current_geo_node(primary)
      end

      describe 'background backfill' do
        it 'verifies model records' do
          model_record.verification_pending!

          expect do
            Geo::VerificationBatchWorker.new.perform(replicator.replicable_name)
          end.to change { model_record.reload.verification_succeeded? }.from(false).to(true)
        end
      end

      describe 'triggered by events' do
        it 'verifies model records' do
          expect do
            Geo::VerificationWorker.new.perform(replicator.replicable_name, replicator.model_record_id)
          end.to change { model_record.reload.verification_succeeded? }.from(false).to(true)
        end
      end
    end

    context 'on a secondary' do
      before do
        # Set the primary checksum
        replicator.verify

        stub_current_geo_node(secondary)
      end

      describe 'background backfill' do
        it 'verifies registries' do
          registry = replicator.registry
          registry.start
          registry.synced!

          expect do
            Geo::VerificationBatchWorker.new.perform(replicator.replicable_name)
          end.to change { registry.reload.verification_succeeded? }.from(false).to(true)
        end
      end

      describe 'triggered by events' do
        it 'verifies registries' do
          registry = replicator.registry
          registry.save!

          expect do
            Geo::VerificationWorker.new.perform(replicator.replicable_name, replicator.model_record_id)
          end.to change { registry.reload.verification_succeeded? }.from(false).to(true)
        end
      end
    end
  end

  def verification_state_value(state_name)
    model_record.class.verification_state_value(state_name)
  end
end
