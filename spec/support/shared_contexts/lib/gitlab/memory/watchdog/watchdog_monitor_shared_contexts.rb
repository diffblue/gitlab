# frozen_string_literal: true

RSpec.shared_context 'as watchdog monitor' do |reason|
  let(:violations_counter) { instance_double(::Prometheus::Client::Counter) }
  let(:violations_handled_counter) { instance_double(::Prometheus::Client::Counter) }
  let(:memory_violation_callback) { proc {} }
  let(:max_strikes) { 2 }
  let(:payload) { {} }

  def stub_prometheus_metrics
    allow(Gitlab::Metrics).to receive(:counter)
                                .with(:gitlab_memwd_violations_total, anything, anything)
                                .and_return(violations_counter)
    allow(Gitlab::Metrics).to receive(:counter)
                                .with(:gitlab_memwd_violations_handled_total, anything, anything)
                                .and_return(violations_handled_counter)

    allow(violations_counter).to receive(:increment)
    allow(violations_handled_counter).to receive(:increment)
  end

  before do
    stub_prometheus_metrics

    allow(::Prometheus::PidProvider).to receive(:worker_id).and_return('worker_1')
    allow(Gitlab::Metrics::System).to receive(:memory_usage_rss).and_return(1024)
  end
end

RSpec.shared_examples 'watchdog monitor when process does not exceed threshold' do
  include_context 'as watchdog monitor'

  it 'does not invoke the memory_violation_callback' do
    expect(memory_violation_callback).not_to receive(:call)

    monitor.call(memory_violation_callback: memory_violation_callback)
  end

  it 'does not increment violations counter' do
    expect(violations_counter).not_to receive(:increment)

    monitor.call(memory_violation_callback: memory_violation_callback)
  end

  it 'does not increment violations handled counter' do
    expect(violations_handled_counter).not_to receive(:increment)

    monitor.call(memory_violation_callback: memory_violation_callback)
  end
end

RSpec.shared_examples 'watchdog monitor when process exceeds threshold' do |reason|
  include_context 'as watchdog monitor'

  context 'when process does not exceed the allowed number of strikes' do
    it 'does not invoke the memory_violation_callback' do
      expect(memory_violation_callback).not_to receive(:call)

      monitor.call(memory_violation_callback: memory_violation_callback)
    end

    it 'increments the violations counter' do
      expect(violations_counter).to receive(:increment).with(reason: reason)

      monitor.call(memory_violation_callback: memory_violation_callback)
    end

    it 'does not increment violations handled counter' do
      expect(violations_handled_counter).not_to receive(:increment)

      monitor.call(memory_violation_callback: memory_violation_callback)
    end
  end

  context 'when process exceeds the allowed number of strikes' do
    let(:max_strikes) { 0 }

    context 'with memory_violation_callback' do
      let(:expected_payload) do
        {
          worker_id: 'worker_1',
          memwd_max_strikes: max_strikes,
          memwd_cur_strikes: 1,
          memwd_rss_bytes: 1024
        }.merge(payload)
      end

      it 'calls the memory_violation callback with proper payload', :aggregate_failures do
        actual_payload = {}

        callback = proc do |payload|
          actual_payload = payload
        end

        expect(callback).to receive(:call).and_call_original
        monitor.call(memory_violation_callback: callback)

        expect(actual_payload).to eq(expected_payload)
      end

      it 'resets strikes' do
        monitor.call(memory_violation_callback: memory_violation_callback)

        expect(monitor.strikes).to eq(0)
      end

      it 'increments both the violations and violations handled counters' do
        expect(violations_counter).to receive(:increment).with(reason: reason)
        expect(violations_handled_counter).to receive(:increment).with(reason: reason)

        monitor.call(memory_violation_callback: memory_violation_callback)
      end
    end

    context 'with no memory_violation callback set' do
      it 'do not raise an error if memory_violation_callback callback is not set' do
        expect { monitor.call(memory_violation_callback: nil) }.not_to raise_error
      end
    end
  end
end
