# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Memory::Watchdog::Monitors::HeapFragmentationMonitor do
  let(:heap_frag_limit_gauge) { instance_double(::Prometheus::Client::Gauge) }
  let(:max_heap_fragmentation) { 0.2 }
  let(:fragmentation) { 0.3 }
  let(:max_strikes) { 2 }

  subject(:monitor) do
    described_class.new(max_heap_fragmentation: max_heap_fragmentation,
                        max_strikes: max_strikes)
  end

  before do
    allow(Gitlab::Metrics).to receive(:gauge)
      .with(:gitlab_memwd_heap_frag_limit, anything)
      .and_return(heap_frag_limit_gauge)
    allow(heap_frag_limit_gauge).to receive(:set)

    allow(Gitlab::Metrics::Memory).to receive(:gc_heap_fragmentation).and_return(fragmentation)
  end

  describe '#initialize' do
    it 'sets the heap fragmentation limit gauge' do
      expect(heap_frag_limit_gauge).to receive(:set).with({}, max_heap_fragmentation)

      monitor
    end

    context 'when no settings are set in the environment' do
      it 'initializes with defaults' do
        monitor = described_class.new

        expect(monitor.max_heap_fragmentation).to eq(described_class::DEFAULT_MAX_HEAP_FRAG)
        expect(monitor.max_strikes).to eq(described_class::DEFAULT_MAX_STRIKES)
      end
    end

    context 'when settings are passed through the environment' do
      before do
        stub_env('GITLAB_MEMWD_MAX_HEAP_FRAG', 1)
        stub_env('GITLAB_MEMWD_MAX_STRIKES', 2)
      end

      it 'initializes with these settings' do
        monitor = described_class.new

        expect(monitor.max_heap_fragmentation).to eq(1)
        expect(monitor.max_strikes).to eq(2)
      end
    end
  end

  describe '#call' do
    it_behaves_like 'watchdog monitor when process exceeds threshold', 'heap_fragmentation' do
      let(:fragmentation) { max_heap_fragmentation + 0.1 }
      let(:payload) do
        {
          message: 'heap fragmentation limit exceeded',
          memwd_cur_heap_frag: fragmentation,
          memwd_max_heap_frag: max_heap_fragmentation
        }
      end
    end

    it_behaves_like 'watchdog monitor when process does not exceed threshold' do
      let(:fragmentation) { max_heap_fragmentation - 0.1 }
    end
  end
end
