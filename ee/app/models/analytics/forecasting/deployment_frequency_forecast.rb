# frozen_string_literal: true

module Analytics
  module Forecasting
    class DeploymentFrequencyForecast < Forecast
      FIT_TIMESPAN = 1.year

      def self.context_class
        Project
      end

      def source_time_series
        @source_time_series ||= begin
          from = FIT_TIMESPAN.ago.to_date
          to = end_date

          metrics = DoraMetricsAggregator.aggregate_for(
            projects: [context],
            environment_tiers: ['production'],
            start_date: from,
            end_date: to,
            metrics: ['deployment_frequency'],
            interval: 'daily').to_h { |v| [v['date'], v['deployment_frequency']] }

          Gitlab::Analytics::DateFiller.new(metrics,
            from: from,
            to: to,
            default_value: 0
          ).fill
        end
      end

      private

      def model_forecast(*)
        super.map do |value|
          value > 0 ? value.round : 0
        end
      end
    end
  end
end
