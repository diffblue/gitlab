# frozen_string_literal: true

RSpec.shared_examples 'aggregator worker examples' do
  def run_worker
    described_class.new.perform
  end

  it_behaves_like 'an idempotent worker'

  context 'when the loaded batch is empty' do
    it 'does nothing' do
      expect(Analytics::CycleAnalytics::AggregatorService).not_to receive(:new)

      run_worker
    end
  end

  it 'invokes the AggregatorService' do
    aggregation = create(:cycle_analytics_aggregation)

    expect(Analytics::CycleAnalytics::AggregatorService).to receive(:new)
      .with(
        aggregation: aggregation,
        mode: expected_mode,
        runtime_limiter: instance_of(Analytics::CycleAnalytics::RuntimeLimiter)
      )
      .and_call_original

    run_worker
  end

  it 'breaks at the second iteration due to overtime' do
    create_list(:cycle_analytics_aggregation, 2)

    first_monotonic_time = 100
    default_max_runtime = Analytics::CycleAnalytics::RuntimeLimiter::DEFAULT_MAX_RUNTIME.to_i
    second_monotonic_time = first_monotonic_time + default_max_runtime + 10

    expect(Gitlab::Metrics::System).to receive(:monotonic_time).and_return(first_monotonic_time, second_monotonic_time)
    expect(Analytics::CycleAnalytics::AggregatorService).to receive(:new).and_call_original.exactly(:once)

    run_worker
  end
end
