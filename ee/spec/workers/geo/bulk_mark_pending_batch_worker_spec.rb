# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::BulkMarkPendingBatchWorker, :geo, feature_category: :geo_replication do
  include EE::GeoHelpers

  let_it_be(:secondary) { create(:geo_node) }

  subject(:worker) { described_class.new }

  before do
    stub_current_geo_node(secondary)
  end

  include_context 'with geo registries shared context'

  with_them do
    describe '#perform' do
      let(:registry) { build_stubbed(registry_factory) }

      it 'calls the bulk_mark_pending_one_batch! method' do
        allow_next_instance_of(::Geo::BulkMarkAsPendingService) do |instance|
          allow(instance).to receive(:remaining_batches_to_bulk_mark_pending).and_return(1)
        end

        expect_any_instance_of(::Geo::BulkMarkAsPendingService) do |instance|
          expect(instance).to receive(:bulk_mark_pending_one_batch!).with(registry_class)
        end

        worker.perform(registry_class.name)
      end
    end

    describe '.perform_with_capacity' do
      it 'resets the Redis cursor to zero' do
        expect_any_instance_of(::Geo::BulkMarkAsPendingService) do |instance|
          expect(instance).to receive(:set_bulk_mark_pending_cursor).with(0).and_call_original
        end

        described_class.perform_with_capacity(registry_class.name)
      end
    end

    include_examples 'an idempotent worker' do
      let(:job_args) { [registry_class.name] }
    end
  end
end
