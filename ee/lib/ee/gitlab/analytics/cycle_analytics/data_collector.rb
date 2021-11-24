# frozen_string_literal: true

module EE
  module Gitlab
    module Analytics
      module CycleAnalytics
        module DataCollector
          def duration_chart_average_data
            strong_memoize(:records_fetcher) do
              if use_aggregated_data_collector?
                aggregated_data_collector.duration_chart_average_data
              else
                duration_chart.average_by_day
              end
            end
          end

          private

          def duration_chart
            @duration_chart ||= ::Gitlab::Analytics::CycleAnalytics::DataForDurationChart.new(stage: stage, params: params, query: query)
          end
        end
      end
    end
  end
end
