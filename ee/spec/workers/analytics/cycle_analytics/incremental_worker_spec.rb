# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Analytics::CycleAnalytics::IncrementalWorker do
  def run_worker
    described_class.new.perform
  end

  it_behaves_like 'an idempotent worker'

  context 'when the vsa_incremental_worker FF is disabled' do
    it 'does nothing' do
      stub_feature_flags(vsa_incremental_worker: false)

      expect(Analytics::CycleAnalytics::Aggregation).not_to receive(:load_batch)

      run_worker
    end
  end

  context 'when the loaded batch is empty' do
    it 'does nothing' do
      expect(Analytics::CycleAnalytics::AggregatorService).not_to receive(:new)

      run_worker
    end
  end

  it 'invokes the AggregatorService' do
    aggregation = create(:cycle_analytics_aggregation)

    expect(Analytics::CycleAnalytics::AggregatorService).to receive(:new).with(aggregation: aggregation).and_call_original

    run_worker
  end

  it 'breaks at the second iteration due to overtime' do
    create_list(:cycle_analytics_aggregation, 2)

    first_monotonic_time = 100
    second_monotonic_time = first_monotonic_time + Analytics::CycleAnalytics::IncrementalWorker::MAX_RUNTIME.to_i + 10

    expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(first_monotonic_time, second_monotonic_time)
    expect(Analytics::CycleAnalytics::AggregatorService).to receive(:new).and_call_original.exactly(:once)

    run_worker
  end
end
