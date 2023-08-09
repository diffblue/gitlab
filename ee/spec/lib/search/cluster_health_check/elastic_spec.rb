# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::ClusterHealthCheck::Elastic, feature_category: :global_search do
  let(:helper) { Gitlab::Elastic::Helper.new }
  let(:client) { helper.client }
  let(:instance) { described_class.new }
  let(:logger) { ::Gitlab::Elasticsearch::Logger.build }

  before do
    allow(Gitlab::Elastic::Helper).to receive(:default).and_return(helper)
    allow(described_class).to receive(:instance).and_return(instance)
    allow(::Gitlab::Elasticsearch::Logger).to receive(:build).and_return(logger)
  end

  describe '.healthy?', :clean_gitlab_redis_cache do
    it 'returns true if the cluster health status is green' do
      allow(instance).to receive(:cluster_status_red?).and_return(false)

      expect(described_class).to be_healthy
    end

    it 'returns true if the cluster health status is red' do
      allow(instance).to receive(:cluster_status_red?).and_return(true)

      expect(described_class).not_to be_healthy
    end

    it 'logs the utilization metrics if the feature flag is enabled' do
      expect(logger).to receive(:info).with(hash_including('message' => 'Utilization metrics'))

      described_class.healthy?
    end

    it 'does not log the utilization metrics if the feature flag is disabled' do
      stub_feature_flags(log_advanced_search_cluster_health_elastic: false)

      expect(logger).not_to receive(:info)

      described_class.healthy?
    end

    it 'returns false if an error is raised' do
      allow(instance).to receive(:cluster_status_red?).and_raise(StandardError, 'error')

      expect(logger).not_to receive(:info)
      expect(logger).to receive(:warn).with('error')

      expect(described_class).not_to be_healthy
    end
  end

  describe '#utilization' do
    let(:health_status) { 'green' }
    let(:load_average) { 10 }
    let(:heap_used_percentage) { 70 }

    let(:health) { { 'status' => health_status } }
    let(:cpu) { { 'cpu' => { 'load_average' => { '1m' => load_average } } } }
    let(:mem) { { 'mem' => { 'heap_used_percent' => heap_used_percentage } } }
    let(:stats) { { 'nodes' => { 'some_node_id' => { 'os' => cpu, 'jvm' => mem } } } }

    subject(:utilization) { instance.utilization }

    before do
      allow(client).to receive_message_chain(:cluster, :health).and_return(health)
      allow(client).to receive_message_chain(:nodes, :stats).and_return(stats)
    end

    it 'returns 75.0' do
      expect(utilization).to eq(75.0)
    end

    context 'if the response is not in the expected format' do
      let(:cpu) { {} }

      it 'raises the error' do
        expect { utilization }.to raise_error(StandardError)
      end
    end

    describe 'values' do
      using RSpec::Parameterized::TableSyntax

      where(:load_average, :heap_used_percentage, :utilization) do
        0   |  0    | 0.000
        10  |  0    | 40.000
        20  |  0    | 57.143
        0   |  50   | 28.571
        10  |  50   | 68.571
        20  |  50   | 85.714
        0   |  100  | 42.105
        10  |  100  | 82.105
        20  |  100  | 99.248
      end

      with_them do
        it 'returns the correct utilization' do
          expect(utilization).to eq(utilization)
        end
      end
    end

    context 'with multiple nodes' do
      let(:node_1) do
        {
          'os' => { 'cpu' => { 'load_average' => { '1m' => 10 } } },
          'jvm' => { 'mem' => { 'heap_used_percent' => 70 } }
        }
      end

      let(:node_2) do
        {
          'os' => { 'cpu' => { 'load_average' => { '1m' => 20 } } },
          'jvm' => { 'mem' => { 'heap_used_percent' => 90 } }
        }
      end

      let(:stats) { { 'nodes' => { 'node_1' => node_1, 'node_2' => node_2 } } }

      it 'returns 87.647' do
        expect(utilization).to eq(87.647)
      end

      context 'when NODE_LIMIT is less than the number of nodes' do
        before do
          stub_const("#{described_class}::NODE_LIMIT", 1)
        end

        it 'only uses the worst performing nodes in utilization calculation' do
          expect(utilization).to eq(97.143)
        end
      end
    end
  end
end
