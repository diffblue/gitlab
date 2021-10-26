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
              'test' =>
                {
                  'after_key' => { 'test' => 'HTML', 'rid' => '3' },
                  'buckets' =>
                    [
                      { 'key' => { 'test' => 'C', 'rid' => '3' }, 'doc_count' => 142 },
                      { 'key' => { 'test' => 'C++', 'rid' => '3' }, 'doc_count' => 6 },
                      { 'key' => { 'test' => 'CSS', 'rid' => '3' }, 'doc_count' => 1 }
                    ]
                },
              'test2' =>
                {
                  'after_key' => { 'test2' => '1' },
                  'buckets' =>
                    [
                      { 'key' => { 'test2' => '1' }, 'doc_count' => 1000 },
                      { 'key' => { 'test2' => '2' }, 'doc_count' => 3 }
                    ]
                }
            }
        }
      end

      it 'parses the results' do
        expected_buckets_1 = [
          { key: { 'test': 'C', 'rid': '3' }, count: 142 },
          { key: { 'test': 'C++', 'rid': '3' }, count: 6 },
          { key: { 'test': 'CSS', 'rid': '3' }, count: 1 }
        ]
        expected_buckets_2 = [
          { key: { 'test2': '1' }, count: 1000 },
          { key: { 'test2': '2' }, count: 3 }
        ]

        expect(subject.length).to eq(2)
        expect(subject.first.name).to eq('test')
        expect(subject.first.buckets).to match_array(expected_buckets_1)
        expect(subject.second.name).to eq('test2')
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
