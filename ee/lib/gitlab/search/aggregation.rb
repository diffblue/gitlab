# frozen_string_literal: true

module Gitlab
  module Search
    class Aggregation
      attr_reader :name, :buckets

      def initialize(name, elastic_aggregation_buckets)
        @name = name
        @buckets = parse_buckets(elastic_aggregation_buckets)
      end

      private

      def parse_buckets(buckets)
        return [] unless buckets

        buckets.map do |b|
          { key: b['key'], count: b['doc_count'] }.merge(b['extra']&.symbolize_keys || {})
        end
      end
    end
  end
end
