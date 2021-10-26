# frozen_string_literal: true

module Gitlab
  module Search
    class AggregationParser
      def self.call(aggregations)
        return [] unless aggregations

        aggregations.keys.map do |key|
          ::Gitlab::Search::Aggregation.new(key, aggregations[key].buckets)
        end
      end
    end
  end
end
