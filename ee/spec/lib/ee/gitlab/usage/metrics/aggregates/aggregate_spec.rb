# frozen_string_literal: true

require 'spec_helper'

feature_category = { feature_category: :service_ping }

RSpec.describe Gitlab::Usage::Metrics::Aggregates::Aggregate, :clean_gitlab_redis_shared_state, feature_category do
  describe '.calculate_count_for_aggregation' do
    let(:end_date) { Date.current }
    let(:namespace) { described_class.to_s.deconstantize.constantize }
    let(:number_of_days) { 7 }
    let(:datasource) { 'redis_hll' }
    let(:time_frame) { "#{number_of_days}d" }
    let(:start_date) { number_of_days.days.ago.to_date }
    let(:params) { { start_date: start_date, end_date: end_date, recorded_at: recorded_at } }
    let(:events) { %w[event1 event2] }
    let(:aggregate) do
      {
        source: datasource,
        operator: 'AND',
        events: events
      }
    end

    let_it_be(:recorded_at) { Time.current.to_i }

    subject(:calculate_count_for_aggregation) do
      described_class
        .new(recorded_at)
        .calculate_count_for_aggregation(aggregation: aggregate, time_frame: time_frame)
    end

    context 'when using known events' do
      before  do
        %w[event1 event2].each do |event_name|
          allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_event?).with(event_name).and_return(true)
        end
      end

      it 'returns the number of unique events for aggregation', :aggregate_failures do
        expect(namespace::SOURCES[datasource])
          .to receive(:calculate_metrics_intersections)
                .with(params.merge(metric_names: events))
                .and_return(5)
        expect(calculate_count_for_aggregation).to eq(5)
      end
    end

    context 'when some of the events are not defined' do
      before do
        allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_event?).with('event1').and_return(true)
        allow(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:known_event?).with('event2').and_return(false)
      end

      context 'with non prod environment' do
        it 'raises error' do
          expect { calculate_count_for_aggregation }.to raise_error namespace::UndefinedEvents
        end
      end

      context 'with prod environment' do
        before do
          stub_rails_env('production')
        end

        it 'returns fallback value' do
          expect(calculate_count_for_aggregation).to be(-1)
        end
      end
    end
  end
end
