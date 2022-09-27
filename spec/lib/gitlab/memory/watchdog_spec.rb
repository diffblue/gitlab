# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Watchdog, :aggregate_failures do
  context 'watchdog' do
    let(:configuration) { instance_double(described_class::Configuration) }
    let(:handler) { instance_double(described_class::NullHandler) }
    let(:logger) { instance_double(::Logger) }
    let(:sleep_time_seconds) { 60 }
    let(:threshold_violated) { false }
    let(:strikes_exceeded) { false }
    let(:violations_counter) { instance_double(::Prometheus::Client::Counter) }
    let(:violations_handled_counter) { instance_double(::Prometheus::Client::Counter) }
    let(:watchdog_iterations) { 1 }
    let(:name) { :monitor_name }
    let(:payload) { { message: 'dummy_text' } }

    subject(:watchdog) do
      described_class.new.tap do |instance|
        # We need to defuse `sleep` and stop the internal loop after 1 iteration
        iterations = 0
        allow(instance).to receive(:sleep) do
          instance.stop if (iterations += 1) > watchdog_iterations
        end
      end
    end

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
      allow(Gitlab::Metrics::System).to receive(:memory_usage_rss).at_least(:once).and_return(1024)
      allow(::Prometheus::PidProvider).to receive(:worker_id).and_return('worker_1')
      allow(described_class::Configuration).to receive(:new).and_return(configuration)
      allow(configuration).to receive(:handler).and_return(handler)
      allow(configuration).to receive(:logger).and_return(logger)
      allow(configuration).to receive(:sleep_time_seconds).and_return(sleep_time_seconds)
      allow(handler).to receive(:call).and_return(true)
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
    end

    describe '#initialize' do
      it 'initialize new configuration' do
        expect(described_class::Configuration).to receive(:new)

        watchdog
      end
    end

    describe '#call' do
      let(:result) { instance_double(described_class::MonitorState::Result) }

      before do
        allow(configuration).to receive_message_chain(:monitors, :call_each).and_yield(result)
        allow(result).to receive(:threshold_violated?).and_return(threshold_violated)
        allow(result).to receive(:strikes_exceeded?).and_return(strikes_exceeded)
        allow(result).to receive(:monitor_name).and_return(name)
        allow(result).to receive(:payload).and_return(payload)
      end

      it 'logs start message once' do
        expect(logger).to receive(:info).once
          .with(
            pid: Process.pid,
            worker_id: 'worker_1',
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds,
            memwd_rss_bytes: 1024,
            message: 'started')

        watchdog.call
      end

      it 'waits for check interval seconds' do
        expect(watchdog).to receive(:sleep).with(sleep_time_seconds)

        watchdog.call
      end

      context 'when gitlab_memory_watchdog ops toggle is off' do
        before do
          stub_feature_flags(gitlab_memory_watchdog: false)
        end

        it 'does not trigger any monitor' do
          expect(configuration).not_to receive(:monitors)
        end
      end

      context 'when process does not exceed threshold' do
        it 'does not increment violations counters' do
          expect(violations_counter).not_to receive(:increment)
          expect(violations_handled_counter).not_to receive(:increment)

          watchdog.call
        end

        it 'does not log violation' do
          expect(logger).not_to receive(:warn)

          watchdog.call
        end

        it 'does not execute handler' do
          expect(handler).not_to receive(:call)

          watchdog.call
        end
      end

      context 'when process exceeds threshold' do
        let(:threshold_violated) { true }

        it 'increments violations counter' do
          expect(violations_counter).to receive(:increment).with(reason: name)

          watchdog.call
        end

        context 'when process does not exceed the allowed number of strikes' do
          it 'does not increment handled violations counter' do
            expect(violations_handled_counter).not_to receive(:increment)

            watchdog.call
          end

          it 'does not log violation' do
            expect(logger).not_to receive(:warn)

            watchdog.call
          end

          it 'does not execute handler' do
            expect(handler).not_to receive(:call)

            watchdog.call
          end
        end

        context 'when process exceeds the allowed number of strikes' do
          let(:strikes_exceeded) { true }

          it 'increments handled violations counter' do
            expect(violations_handled_counter).to receive(:increment).with(reason: name)

            watchdog.call
          end

          it 'logs violation' do
            expect(logger).to receive(:warn)
              .with(
                pid: Process.pid,
                worker_id: 'worker_1',
                memwd_handler_class: handler.class.name,
                memwd_sleep_time_s: sleep_time_seconds,
                memwd_rss_bytes: 1024,
                message: 'dummy_text')

            watchdog.call
          end

          it 'executes handler' do
            expect(handler).to receive(:call)

            watchdog.call
          end

          context 'when enforce_memory_watchdog ops toggle is off' do
            before do
              stub_feature_flags(enforce_memory_watchdog: false)
            end

            it 'always uses the NullHandler' do
              expect(handler).not_to receive(:call)
              expect(described_class::NullHandler.instance).to receive(:call).and_return(true)

              watchdog.call
            end
          end

          context 'when multiple monitors exceeds threshold' do
            it 'only calls the handler once' do
              expect(configuration).to receive_message_chain(:monitors, :call_each).and_yield(result).and_yield(result)

              expect(handler).to receive(:call).once.and_return(true)

              watchdog.call
            end
          end
        end
      end

      it 'logs stop message once' do
        expect(logger).to receive(:info).once
          .with(
            pid: Process.pid,
            worker_id: 'worker_1',
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds,
            memwd_rss_bytes: 1024,
            message: 'stopped')

        watchdog.call
      end
    end

    describe '#configure' do
      it 'yields block' do
        expect { |b| watchdog.configure(&b) }.to yield_with_args(configuration)
      end
    end
  end

  context 'handlers' do
    context 'NullHandler' do
      subject(:handler) { described_class::NullHandler.instance }

      describe '#call' do
        it 'does nothing' do
          expect(handler.call).to be(false)
        end
      end
    end

    context 'TermProcessHandler' do
      subject(:handler) { described_class::TermProcessHandler.new(42) }

      describe '#call' do
        it 'sends SIGTERM to the current process' do
          expect(Process).to receive(:kill).with(:TERM, 42)

          expect(handler.call).to be(true)
        end
      end
    end

    context 'PumaHandler' do
      # rubocop: disable RSpec/VerifiedDoubles
      # In tests, the Puma constant is not loaded so we cannot make this an instance_double.
      let(:puma_worker_handle_class) { double('Puma::Cluster::WorkerHandle') }
      let(:puma_worker_handle) { double('worker') }
      # rubocop: enable RSpec/VerifiedDoubles

      subject(:handler) { described_class::PumaHandler.new({}) }

      before do
        stub_const('::Puma::Cluster::WorkerHandle', puma_worker_handle_class)
      end

      describe '#call' do
        it 'invokes orderly termination via Puma API' do
          expect(puma_worker_handle_class).to receive(:new).and_return(puma_worker_handle)
          expect(puma_worker_handle).to receive(:term)

          expect(handler.call).to be(true)
        end
      end
    end
  end
end
