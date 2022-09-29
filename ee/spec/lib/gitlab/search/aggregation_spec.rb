# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Search::Aggregation do
  describe 'parsing bucket results' do
    subject { described_class.new('language', aggregation_buckets) }

    context 'when elasticsearch buckets are provided' do
      let(:aggregation_buckets) { [{ 'key': { 'language': 'ruby' }, 'doc_count': 10 }, { 'key': { 'language': 'java' }, 'doc_count': 20 }].map(&:with_indifferent_access) }

      it 'parses the results' do
        expected = [{ key: { 'language': 'ruby' }, count: 10 }, { key: { 'language': 'java' }, count: 20 }]

        expect(subject.buckets).to match_array(expected)
      end
    end

    context 'when extra is provided' do
      let(:aggregation_buckets) do
        [
          { 'key': 'ruby', 'doc_count': 10, extra: { 'foo': 'bar' }.with_indifferent_access },
          { 'key': 'java', 'doc_count': 20, extra: { 'foo': 'baz' }.with_indifferent_access }
        ].map(&:with_indifferent_access)
      end

      it 'merges the extra field' do
        expected = [{ key: 'ruby', count: 10, foo: 'bar' }, { key: 'java', count: 20, foo: 'baz' }]

        expect(subject.buckets).to match_array(expected)
      end
    end

    context 'when elasticsearch buckets are not provided' do
      let(:aggregation_buckets) { nil }

      it 'parses the results' do
        expect(subject.buckets).to match_array([])
      end
    end
  end
end
