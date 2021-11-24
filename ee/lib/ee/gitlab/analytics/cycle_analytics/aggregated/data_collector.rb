# frozen_string_literal: true

module EE
  module Gitlab
    module Analytics
      module CycleAnalytics
        module Aggregated
          module DataCollector
            def duration_chart_average_data
              ::Gitlab::Analytics::CycleAnalytics::Aggregated::DataForDurationChart
                .new(stage: stage, params: params, query: query)
                .average_by_day
            end
          end
        end
      end
    end
  end
end
