# frozen_string_literal: true

require 'spec_helper'
require_dependency 'gitlab/cluster/lifecycle_events'

RSpec.describe Gitlab::Memory::Watchdog::Monitors::MemoryGrowthMonitor do
  let(:primary_memory) { 2048 }
  let(:worker_memory) { 0 }
  let(:max_mem_growth) { 2 }
  let(:max_strikes) { 2 }

  subject(:monitor) do
    described_class.new(max_mem_growth: max_mem_growth,
                        max_strikes: max_strikes)
  end

  before do
    allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).and_return({ uss: worker_memory })
    allow(Gitlab::Metrics::System).to receive(:memory_usage_uss_pss).with(
      pid: Gitlab::Cluster::PRIMARY_PID
    ).and_return({ uss: primary_memory })
  end

  describe '#initialize' do
    context 'when no settings are set in the environment' do
      it 'initializes with defaults' do
        monitor = described_class.new

        expect(monitor.max_mem_growth).to eq(described_class::DEFAULT_MAX_MEM_GROWTH)
        expect(monitor.max_strikes).to eq(described_class::DEFAULT_MAX_STRIKES)
      end
    end

    context 'when settings are passed through the environment' do
      before do
        stub_env('GITLAB_MEMWD_MAX_MEM_GROWTH', 4)
        stub_env('GITLAB_MEMWD_MAX_STRIKES', 2)
      end

      it 'initializes with these settings' do
        monitor = described_class.new

        expect(monitor.max_mem_growth).to eq(4)
        expect(monitor.max_strikes).to eq(2)
      end
    end
  end

  describe '#call' do
    it_behaves_like 'watchdog monitor when process exceeds threshold', 'memory_growth' do
      let(:worker_memory) { max_mem_growth * primary_memory + 1 }
      let(:payload) do
        {
          message: 'memory limit exceeded',
          memwd_max_uss_bytes: max_mem_growth * primary_memory,
          memwd_ref_uss_bytes: primary_memory,
          memwd_uss_bytes: worker_memory
        }
      end
    end

    it_behaves_like 'watchdog monitor when process does not exceed threshold' do
      let(:worker_memory) { max_mem_growth * primary_memory - 1 }
    end
  end
end
