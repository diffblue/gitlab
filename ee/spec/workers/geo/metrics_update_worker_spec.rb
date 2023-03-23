# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::MetricsUpdateWorker, :geo, feature_category: :geo_replication do
  include ::EE::GeoHelpers

  describe '#perform' do
    let(:primary) { create(:geo_node, :primary) }

    before do
      stub_current_geo_node(primary)

      # We disable the transaction_open? check because Gitlab::Database::BatchCounter.batch_count
      # is not allowed within a transaction but all RSpec tests run inside of a transaction.
      stub_batch_counter_transaction_open_check
    end

    include_examples 'an idempotent worker' do
      it 'delegates to MetricsUpdateService' do
        service = Geo::MetricsUpdateService.new
        allow(Geo::MetricsUpdateService).to receive(:new).and_return(service).at_least(1).time

        expect(service).to receive(:execute).and_call_original.at_least(1).time

        perform_multiple
      end
    end
  end
end
