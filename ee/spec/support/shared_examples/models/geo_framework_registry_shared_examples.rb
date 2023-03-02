# frozen_string_literal: true

RSpec.shared_examples 'a Geo framework registry' do
  let(:registry_class_factory) { described_class.underscore.tr('/', '_').to_sym }

  context 'obligatory fields check' do
    it 'has expected fields or methods' do
      registry = create(registry_class_factory) # rubocop:disable Rails/SaveBang
      expected_fields = %i[
        state retry_count last_sync_failure retry_at last_synced_at created_at
      ]

      expected_fields.each do |field|
        expect(registry).to respond_to(field)
      end
    end
  end

  context 'scopes' do
    describe 'sync_timed_out' do
      it 'return correct records' do
        record = create(registry_class_factory, :started, last_synced_at: 9.hours.ago)
        create(registry_class_factory, :started, last_synced_at: 1.hour.ago)
        create(registry_class_factory, :failed, last_synced_at: 9.hours.ago)

        expect(described_class.sync_timed_out).to eq [record]
      end
    end
  end

  context 'finders' do
    let!(:failed_item1) { create(registry_class_factory, :failed, retry_at: 1.minute.ago) }
    let!(:failed_item2) { create(registry_class_factory, :failed, retry_at: 1.minute.ago) }
    let!(:unsynced_item1) { create(registry_class_factory) } # rubocop:disable Rails/SaveBang
    let!(:unsynced_item2) { create(registry_class_factory) } # rubocop:disable Rails/SaveBang

    describe '.find_registries_never_attempted_sync' do
      it 'returns unsynced items' do
        result = described_class.find_registries_never_attempted_sync(batch_size: 10)

        expect(result).to include(unsynced_item1, unsynced_item2)
      end

      it 'returns items that never have an attempt to sync except some specific item ID' do
        except_id = unsynced_item1.model_record_id

        result = described_class.find_registries_never_attempted_sync(batch_size: 10, except_ids: [except_id])

        expect(result).to include(unsynced_item2)
        expect(result).not_to include(unsynced_item1)
      end
    end

    describe '.find_registries_needs_sync_again' do
      it 'returns failed items' do
        result = described_class.find_registries_needs_sync_again(batch_size: 10)

        expect(result).to include(failed_item1, failed_item2)
      end

      it 'returns failed items except some specific item ID' do
        except_id = failed_item1.model_record_id

        result = described_class.find_registries_needs_sync_again(batch_size: 10, except_ids: [except_id])

        expect(result).to include(failed_item2)
        expect(result).not_to include(failed_item1)
      end

      it 'orders records according to retry_at' do
        failed_item1.update!(retry_at: 2.days.ago)
        failed_item2.update!(retry_at: 4.days.ago)

        result = described_class.find_registries_needs_sync_again(batch_size: 10)

        expect(result.first).to eq failed_item2
      end
    end
  end

  describe '.fail_sync_timeouts' do
    it 'marks started records as failed if they are expired' do
      record1 = create(registry_class_factory, :started, last_synced_at: 9.hours.ago)
      record2 = create(registry_class_factory, :started, last_synced_at: 1.hour.ago) # not yet expired

      described_class.fail_sync_timeouts

      expect(record1.reload.state).to eq described_class::STATE_VALUES[:failed]
      expect(record2.reload.state).to eq described_class::STATE_VALUES[:started]
    end
  end

  describe '#failed!' do
    let(:registry) { create(registry_class_factory, :started) }
    let(:message) { 'Foo' }

    it 'sets last_sync_failure with message' do
      registry.failed!(message: message)

      expect(registry.last_sync_failure).to include(message)
    end

    it 'truncates a long last_sync_failure' do
      registry.failed!(message: 'a' * 256)

      expect(registry.last_sync_failure).to eq('a' * 252 + '...')
    end

    it 'increments retry_count' do
      registry.failed!(message: message)

      expect(registry.retry_count).to eq(1)

      registry.start
      registry.failed!(message: message)

      expect(registry.retry_count).to eq(2)
    end

    it 'sets retry_at to a time in the future' do
      now = Time.current

      registry.failed!(message: message)

      expect(registry.retry_at >= now).to be_truthy
    end

    context 'when an error is given' do
      it 'includes error.message in last_sync_failure' do
        registry.failed!(message: message, error: StandardError.new('bar'))

        expect(registry.last_sync_failure).to eq('Foo: bar')
      end
    end

    context 'when missing_on_primary is not given' do
      it 'caps retry_at to default 1 hour' do
        registry.retry_count = 9999
        registry.failed!(message: message)

        expect(registry.retry_at).to be_within(10.minutes).of(1.hour.from_now)
      end
    end

    context 'when missing_on_primary is falsey' do
      it 'caps retry_at to default 1 hour' do
        registry.retry_count = 9999
        registry.failed!(message: message, missing_on_primary: false)

        expect(registry.retry_at).to be_within(10.minutes).of(1.hour.from_now)
      end
    end

    context 'when missing_on_primary is truthy' do
      it 'caps retry_at to 4 hours' do
        registry.retry_count = 9999
        registry.failed!(message: message, missing_on_primary: true)

        expect(registry.retry_at).to be_within(10.minutes).of(4.hours.from_now)
      end
    end
  end

  describe '#synced!' do
    let(:registry) { create(registry_class_factory, :started) }

    it 'mark as synced', :aggregate_failures do
      registry.synced!

      expect(registry.reload).to have_attributes(
        retry_count: 0,
        retry_at: nil,
        last_sync_failure: nil
      )

      expect(registry.synced?).to be_truthy
    end

    context 'when a sync was scheduled after the last sync finishes' do
      before do
        registry.update!(
          state: 'pending',
          retry_count: 2,
          retry_at: 1.hour.ago,
          last_sync_failure: 'Something went wrong'
        )

        registry.synced!
      end

      it 'does not reset state' do
        expect(registry.reload.pending?).to be_truthy
      end

      it 'resets the other sync state fields' do
        expect(registry.reload).to have_attributes(
          retry_count: 0,
          retry_at: nil,
          last_sync_failure: nil
        )
      end
    end
  end

  describe '#pending!' do
    context 'when a sync is currently running' do
      let(:registry) { create(registry_class_factory, :started) }

      it 'successfully moves state to pending' do
        expect do
          registry.pending!
        end.to change { registry.pending? }.from(false).to(true)
      end
    end

    context 'when the registry has recorded a failure' do
      let(:registry) { create(registry_class_factory, :failed) }

      it 'clears failure retry fields' do
        expect do
          registry.pending!
          registry.reload
        end.to change { registry.retry_at }.from(a_kind_of(ActiveSupport::TimeWithZone)).to(nil)
           .and change { registry.retry_count }.to(0)
      end
    end
  end
end
