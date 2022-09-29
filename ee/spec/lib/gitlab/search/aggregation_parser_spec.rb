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
      context 'code search' do
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

      context 'issue search with labels aggregations' do
        let(:label1) { create(:label) }
        let(:label2) { create(:label) }

        let!(:elastic_aggregations) do
          {
            'aggregations' =>
              {
                'labels' =>
                  {
                    'buckets' =>
                      [
                        { 'key' => label1.id.to_s, 'doc_count' => 14 },
                        { 'key' => label2.id.to_s, 'doc_count' => 6 }
                      ]
                  }
              }
          }
        end

        it 'adds label-specific fields' do
          expect { subject }.not_to exceed_query_limit(5)

          expect(subject.length).to eq(1)
          expect(subject.first.name).to eq('labels')
          expect(subject.first.buckets.first.symbolize_keys).to match(
            key: label1.id.to_s,
            count: 14,
            title: label1.title,
            type: label1.type,
            color: label1.color.to_s,
            parent_full_name: label1.project.full_name
          )
          expect(subject.first.buckets.last.symbolize_keys).to match(
            key: label2.id.to_s,
            count: 6,
            title: label2.title,
            type: label2.type,
            color: label2.color.to_s,
            parent_full_name: label2.project.full_name
          )
        end
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
