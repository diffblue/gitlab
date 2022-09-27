# frozen_string_literal: true

require 'spec_helper'
require_dependency 'gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog::Configuration do
  subject(:configuration) { described_class.new }

  describe '#initialize' do
    it 'initialize monitors' do
      expect(configuration.monitors).to be_an_instance_of(described_class::MonitorStack)
    end
  end

  describe '#handler' do
    context 'when handler is not set' do
      it 'defaults to NullHandler' do
        expect(configuration.handler).to be(Gitlab::Memory::Watchdog::NullHandler.instance)
      end
    end
  end

  describe '#logger' do
    context 'when logger is not set, defaults to stdout logger' do
      it 'defaults to Logger' do
        expect(configuration.logger).to be_an_instance_of(Gitlab::Logger)
      end
    end
  end

  describe '#sleep_time_seconds' do
    context 'when sleep_time_seconds is not set' do
      it 'defaults to SLEEP_TIME_SECONDS' do
        expect(configuration.sleep_time_seconds).to eq(described_class::SLEEP_TIME_SECONDS)
      end
    end
  end

  describe '#monitors' do
    context 'when monitors are configured to be used' do
      let(:monitor) { monitor_class.new }
      let(:monitor_class) do
        Class.new do
          def call; end
        end
      end

      it 'builds monitor with args and provided block' do
        block = -> {}
        expect(monitor_class).to receive(:new).with(custom_arg: 'dummy_text').and_yield.and_return(monitor)
        expect(Gitlab::Memory::Watchdog::MonitorState).to receive(:new).with(monitor, max_strikes: 5)

        configuration.monitors.use(monitor_class, custom_arg: 'dummy_text', max_strikes: 5, &block)
      end

      context 'when monitor is used twice' do
        before do
          allow_next_instance_of(Gitlab::Memory::Watchdog::MonitorState) do |monitor|
            allow(monitor).to receive(:call)
          end

          configuration.monitors.use(monitor_class)
          configuration.monitors.use(monitor_class)
        end

        it 'calls same monitor only once' do
          expect do |b|
            configuration.monitors.call_each(&b)
          end.to yield_control.once
        end
      end
    end
  end
end
