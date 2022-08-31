# frozen_string_literal: true

require 'spec_helper'
require_dependency 'gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog::Configuration do
  subject(:configuration) { described_class.new }

  describe '#initialize' do
    it 'initialize monitors' do
      expect(described_class::MonitorStack).to receive(:new)

      configuration
    end
  end

  describe '#handler' do
    context 'when handler is not set' do
      it 'defaults to NullHandler' do
        expect(Gitlab::Memory::Watchdog::NullHandler).to receive(:instance)

        configuration.handler
      end
    end
  end

  describe '#logger' do
    context 'when logger is not set, defaults to stdout logger' do
      it 'defaults to NullHandler' do
        expect(Logger).to receive(:new).with($stdout)

        configuration.logger
      end
    end
  end

  describe '#sleep_time_seconds' do
    context 'when sleep_time_seconds is not set' do
      context 'when GITLAB_MEMWD_SLEEP_TIME_SEC environment variable is set' do
        before do
          stub_env('GITLAB_MEMWD_SLEEP_TIME_SEC', 5)
        end

        it 'uses environment settings' do
          expect(configuration.sleep_time_seconds).to be(5)
        end
      end

      context 'when environment variable is not set' do
        it 'defaults to DEFAULT_SLEEP_TIME_SECONDS' do
          expect(configuration.sleep_time_seconds).to be(described_class::DEFAULT_SLEEP_TIME_SECONDS)
        end
      end
    end
  end

  describe '#monitors' do
    context 'when monitors are configured to be used' do
      let(:monitor_class1) do
        Class.new(Gitlab::Memory::Watchdog::Monitors::BaseMonitor) do
          def initialize(custom_attr: nil); end
        end
      end

      let(:monitor_class2) { Class.new(Gitlab::Memory::Watchdog::Monitors::BaseMonitor) }

      before do
        stub_const('DummyMonitor1', monitor_class1)
        stub_const('DummyMonitor2', monitor_class2)
      end

      it 'builds monitor with args and provided block' do
        block = -> {}
        expect(DummyMonitor1).to receive(:new).with(custom_attr: 'custom', max_strikes: 5).and_yield

        configuration.monitors.use(DummyMonitor1, custom_attr: 'custom', max_strikes: 5, &block)
      end

      it 'iterates over the nodes in a document' do
        configuration.monitors.use(DummyMonitor1)
        configuration.monitors.use(DummyMonitor2)

        expect { |b| configuration.monitors.each(&b) }
          .to yield_successive_args(an_instance_of(DummyMonitor1), an_instance_of(DummyMonitor2))
      end
    end
  end
end
