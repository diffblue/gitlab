# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Search::AggregationParser do
  let(:search) do
    Elasticsearch::Model::Searching::SearchRequest.new(Issue, '*').tap do |request|
      allow(request).to receive(:execute!).and_return(elastic_aggregations)
    end
  end

  let(:aggregations) do
    Elasticsearch::Model::Response::Response.new(Issue, search).aggregations
  end

  describe '.call' do
    subject { described_class.call(aggregations) }

    context 'when elasticsearch buckets are provided' do
      let(:elastic_aggregations) do
        {
          'aggregations' =>
            {
              'terms_agg' =>
                {
                  'buckets' =>
                    [
                      { 'key' => 'Markdown', 'doc_count' => 142 },
                      { 'key' => 'C', 'doc_count' => 6 },
                      { 'key' => 'C++', 'doc_count' => 1 }
                    ]
                },
              'composite_agg' =>
                {
                  'after_key' => { 'composite_agg' => 'Makefile' },
                  'buckets' =>
                    [
                      { 'key' => { 'composite_agg' => 'JavaScript' }, 'doc_count' => 1000 },
                      { 'key' => { 'composite_agg' => 'Java' }, 'doc_count' => 3 }
                    ]
                }
            }
        }
      end

      it 'parses the results' do
        expected_buckets_1 = [
          { key: 'Markdown', count: 142 },
          { key: 'C', count: 6 },
          { key: 'C++', count: 1 }
        ]
        expected_buckets_2 = [
          { key: { 'composite_agg': 'JavaScript' }, count: 1000 },
          { key: { 'composite_agg': 'Java' }, count: 3 }
        ]

        expect(subject.length).to eq(2)
        expect(subject.first.name).to eq('terms_agg')
        expect(subject.first.buckets).to match_array(expected_buckets_1)
        expect(subject.second.name).to eq('composite_agg')
        expect(subject.second.buckets).to match_array(expected_buckets_2)
      end
    end

    context 'aggregations are not present' do
      let(:elastic_aggregations) { {} }

      it 'parses the results' do
        expect(subject).to match_array([])
      end
    end
  end
end
