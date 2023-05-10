# frozen_string_literal: true

module Analytics
  module Forecasting
    class DeploymentFrequencyForecast < Forecast
      FIT_TIMESPAN = 1.year

      def source_time_series
        @source_time_series ||= begin
          from = FIT_TIMESPAN.ago.to_date
          to = end_date

          metrics = Dora::DailyMetrics.for_project_production(context)
                                      .in_range_of(from, to)
                                      .order(:date)
                                      .pluck(:date, :deployment_frequency).to_h

          fill_missing_values!(metrics, from: from, to: to)
        end
      end

      private

      def model_forecast(*)
        super.map(&:round)
      end
    end
  end
end
