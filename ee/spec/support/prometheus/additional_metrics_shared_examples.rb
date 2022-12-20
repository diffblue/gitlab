# frozen_string_literal: true

RSpec.shared_examples 'additional custom metrics query' do
  include Prometheus::MetricBuilders

  let(:metric_group_class) { Gitlab::Prometheus::MetricGroup }
  let(:metric_class) { Gitlab::Prometheus::Metric }

  let(:metric_names) { %w{metric_a metric_b} }

  let(:query_range_result) do
    [{ 'metric': {}, 'values': [[1488758662.506, '0.00002996364761904785'], [1488758722.506, '0.00003090239047619091']] }]
  end

  let(:client) { double('prometheus_client') }
  let(:query_result) { described_class.new(client).query(*query_params) }
  let(:project) { create(:project, :repository) }
  let(:environment) { create(:environment, slug: 'environment-slug', project: project) }

  before do
    allow(client).to receive(:label_values).and_return(metric_names)
    allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group(metrics: [simple_metric])])
  end

  context 'with custom metrics' do
    let!(:metric) { create(:prometheus_metric, project: project) }

    before do
      allow(client).to receive(:query_range).with('avg(metric)', any_args).and_return(query_range_result)
    end

    context 'without common metrics' do
      before do
        allow(metric_group_class).to receive(:common_metrics).and_return([])
      end

      it 'return group data for custom metric' do
        queries_with_result = { queries: [{ query_range: 'avg(metric)', unit: 'm/s', label: 'legend', result: query_range_result }] }
        expect(query_result.to_json).to match_schema('prometheus/additional_metrics_query_result')

        expect(query_result.count).to eq(1)
        expect(query_result.first[:metrics].count).to eq(1)

        expect(query_result.first[:metrics].first).to include(queries_with_result)
      end
    end

    context 'with common metrics' do
      before do
        allow(client).to receive(:query_range).with('query_range_a', any_args).and_return(query_range_result)

        allow(metric_group_class).to receive(:common_metrics).and_return([simple_metric_group(metrics: [simple_metric])])
      end

      it 'return group data for custom metric' do
        custom_queries_with_result = { queries: [{ query_range: 'avg(metric)', unit: 'm/s', label: 'legend', result: query_range_result }] }
        common_queries_with_result = { queries: [{ query_range: 'query_range_a', result: query_range_result }] }

        expect(query_result.to_json).to match_schema('prometheus/additional_metrics_query_result')

        expect(query_result.count).to eq(2)
        expect(query_result).to all(satisfy { |r| r[:metrics].count == 1 })

        expect(query_result[0][:metrics].first).to include(common_queries_with_result)
        expect(query_result[1][:metrics].first).to include(custom_queries_with_result)
      end
    end
  end
end
