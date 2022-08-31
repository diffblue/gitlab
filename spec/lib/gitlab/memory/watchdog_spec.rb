# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Watchdog, :aggregate_failures do
  context 'watchdog' do
    let(:configuration) { instance_double(described_class::Configuration) }
    let(:monitor1) { instance_double(described_class::Monitors::BaseMonitor) }
    let(:monitor2) { instance_double(described_class::Monitors::BaseMonitor) }
    let(:monitors) { [monitor1, monitor2] }
    let(:handler) { instance_double(described_class::NullHandler) }
    let(:logger) { instance_double(::Logger) }
    let(:sleep_time_seconds) { 60 }

    subject(:watchdog) do
      described_class.new.tap do |instance|
        # We need to defuse `sleep` and stop the internal loop after 1 iteration
        allow(instance).to receive(:sleep) do
          # stop watchdog after one sleep
          instance.stop
        end
      end
    end

    before do
      allow(described_class::Configuration).to receive(:new).and_return(configuration)
      allow(configuration).to receive(:handler).and_return(handler)
      allow(configuration).to receive(:logger).and_return(logger)
      allow(configuration).to receive(:sleep_time_seconds).and_return(sleep_time_seconds)
      allow(configuration).to receive(:monitors).and_return(monitors)
      allow(handler).to receive(:call)
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
      allow(monitor1).to receive(:call)
      allow(monitor2).to receive(:call)
    end

    describe '#call' do
      it 'logs start message once' do
        expect(logger).to receive(:info).once
          .with(
            pid: Process.pid,
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds,
            message: 'started')

        watchdog.call
      end

      it 'waits for check interval seconds' do
        expect(watchdog).to receive(:sleep).with(sleep_time_seconds)

        watchdog.call
      end

      it 'executes monitors with memory_violation callback' do
        expect(monitors).to all(receive(:call).with(memory_violation_callback: anything))

        watchdog.call
      end

      context 'when gitlab_memory_watchdog ops toggle is off' do
        before do
          stub_feature_flags(gitlab_memory_watchdog: false)
        end

        it 'does not trigger any monitor' do
          monitors.each do |monitor|
            expect(monitor).not_to receive(:call)
          end
        end
      end

      it 'logs stop message once' do
        expect(logger).to receive(:info).once
          .with(
            pid: Process.pid,
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds,
            message: 'stopped')

        watchdog.call
      end
    end

    describe '#memory_violation_callback' do
      let(:payload) { { message: 'dummy_text' } }

      subject(:memory_violation_callback) { watchdog.memory_violation_callback.call(payload) }

      it 'invoke sidekiq logger warn' do
        expect(logger).to receive(:warn)
          .with(
            pid: Process.pid,
            memwd_handler_class: handler.class.name,
            memwd_sleep_time_s: sleep_time_seconds,
            message: 'dummy_text')

        memory_violation_callback
      end

      it 'executes handler' do
        expect(handler).to receive(:call)

        memory_violation_callback
      end

      context 'when enforce_memory_watchdog ops toggle is off' do
        before do
          stub_feature_flags(enforce_memory_watchdog: false)
        end

        it 'always uses the NullHandler' do
          expect(handler).not_to receive(:call)
          expect(described_class::NullHandler.instance).to receive(:call).and_return(true)

          memory_violation_callback
        end
      end

      context 'when memory_violation_callback is triggered multiple times' do
        it 'only calls the handler once' do
          expect(handler).to receive(:call).once.and_return(true)

          memory_violation_callback
          memory_violation_callback
        end
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
