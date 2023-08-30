# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::BulkMarkVerificationPendingService, feature_category: :geo_replication do
  include_context 'with geo registries shared context'

  with_them do
    let(:service) { described_class.new(registry_class.name) }

    describe '#bulk_mark_update_one_batch!' do
      before do
        # We reset the bulk mark update cursor to 0
        # so the service starts from the registry ID 0
        service.set_bulk_mark_update_cursor(0)
      end

      it 'marks registries as they need verification' do
        records = [
          create(
            registry_factory,
            :synced,
            verification_state: registry_class.verification_state_value(:verification_failed),
            verification_failure: 'Failed reason',
            verified_at: Time.current
          ),
          create(
            registry_factory,
            :synced,
            verification_state: registry_class.verification_state_value(:verification_succeeded),
            verification_checksum: 'abc123',
            verified_at: Time.current
          ),
          create(
            registry_factory,
            :synced,
            verification_state: registry_class.verification_state_value(:verification_started),
            verified_at: Time.current
          )
        ]

        service.bulk_mark_update_one_batch!

        records.each do |record|
          expect(record.reload.verification_state)
            .to eq registry_class::VERIFICATION_STATE_VALUES[:verification_pending]
        end
      end
    end

    describe '#remaining_batches_to_bulk_mark_update' do
      let(:max_running_jobs) { 1 }

      context 'when there are remaining batches for registries with verification pending' do
        it 'returns the number of remaining batches' do
          create(
            registry_factory,
            :synced,
            verification_state: registry_class.verification_state_value(:verification_started)
          )

          expect(service.remaining_batches_to_bulk_mark_update(max_batch_count: max_running_jobs))
            .to eq(1)
        end
      end

      context 'when there are not remaining batches for registries with verification not pending' do
        it 'returns zero remaining batches' do
          create_list(
            registry_factory,
            3,
            :synced,
            verification_state: registry_class.verification_state_value(:verification_pending)
          )

          expect(service.remaining_batches_to_bulk_mark_update(max_batch_count: max_running_jobs))
            .to eq(0)
        end
      end
    end

    describe '#set_bulk_mark_update_cursor' do
      let(:last_id_updated) { 100 }
      let(:bulk_mark_pending_redis_key) { "geo:latest_id_marked_as_verification_pending:#{registry_class.table_name}" }

      it 'sets redis shared state cursor key' do
        service.set_bulk_mark_update_cursor(last_id_updated)

        expect(service.send(:get_bulk_mark_update_cursor)).to eq(100)
      end
    end
  end
end
