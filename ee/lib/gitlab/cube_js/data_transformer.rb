# frozen_string_literal: true

module Gitlab
  module CubeJs
    class DataTransformer
      def initialize(query: {}, results: [])
        @date_range_filters = query.fetch('filters', []).select { |filter| filter['operator'] == 'inDateRange' }
        @measures = query.fetch('measures', [])
        @results = results
      end

      def transform
        return @results if @date_range_filters.empty? || @measures.empty? || @results.empty?

        @results.each_with_index do |result, k|
          @results[k] = fill_missing_dates(result)
        end

        @results
      end

      private

      # This method only works with `day` based time dimensions
      # We should upstream to support all time dimension types
      # https://gitlab.com/gitlab-org/gitlab/-/issues/417231
      def fill_missing_dates(result)
        @date_range_filters.each do |filter|
          dimension = filter['member']
          missing_dates = missing_dates(result, filter, dimension)

          missing_dates.each do |date|
            # Some query results are a totalled value rather than getting returned for each day
            next unless result.dig('data', 0, "#{dimension}.day")

            new_data = { "#{dimension}.day": date, "#{dimension}": date }

            @measures.each do |measure|
              # Cube numbers are passed as strings, most likely to avoid float limitations
              new_data = new_data.merge({ "#{measure}": "0" })
            end

            result['data'].push(new_data)
          end
        end

        result
      end

      def missing_dates(result, filter, dimension)
        start_date = filter['values'][0].to_date
        end_date = filter['values'][1].to_date
        range = (start_date..end_date).map { |d| d.strftime('%Y-%m-%dT%H:%M:%S.%3N') }

        dates_with_data = result['data'].map { |h| h[dimension] }.uniq # rubocop:disable Rails/Pluck

        range - dates_with_data
      end
    end
  end
end
