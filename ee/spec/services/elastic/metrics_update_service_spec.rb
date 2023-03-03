# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Elastic::MetricsUpdateService, :prometheus, feature_category: :global_search do
  subject { described_class.new }

  describe '#execute' do
    it 'sets gauges' do
      expect(Elastic::ProcessBookkeepingService).to receive(:queue_size).and_return(4)
      expect(Elastic::ProcessInitialBookkeepingService).to receive(:queue_size).and_return(6)
      expect(Elastic::IndexingControlService).to receive(:queue_size).and_return(2)

      incremental_gauge_double = instance_double(Prometheus::Client::Gauge)
      expect(Gitlab::Metrics).to receive(:gauge)
        .with(:global_search_bulk_cron_queue_size, anything, {}, :max)
        .and_return(incremental_gauge_double)

      initial_gauge_double = instance_double(Prometheus::Client::Gauge)
      expect(Gitlab::Metrics).to receive(:gauge)
        .with(:global_search_bulk_cron_initial_queue_size, anything, {}, :max)
        .and_return(initial_gauge_double)

      awaiting_indexing_gauge = instance_double(Prometheus::Client::Gauge)
      expect(Gitlab::Metrics).to receive(:gauge)
        .with(:global_search_awaiting_indexing_queue_size, anything, {}, :max)
        .and_return(awaiting_indexing_gauge)

      expect(incremental_gauge_double).to receive(:set).with({}, 4)
      expect(initial_gauge_double).to receive(:set).with({}, 6)
      expect(awaiting_indexing_gauge).to receive(:set).with({}, 2)

      subject.execute
    end
  end
end
