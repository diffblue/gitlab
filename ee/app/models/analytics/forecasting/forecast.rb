# frozen_string_literal: true

module Analytics
  module Forecasting
    class Forecast
      include ActiveModel::Model

      MINIMAL_SCORE_THRESHOLD = 0.4

      attr_accessor :context, :type, :horizon

      def self.for(type)
        DeploymentFrequencyForecast if type == 'deployment_frequency'
      end

      def initialize(*args)
        super

        @end_date = Date.today
      end

      def status
        good_fit? ? 'ready' : 'unavailable'
      end

      def values
        return [] unless good_fit?

        @values ||= model_forecast.map.with_index do |value, i|
          [end_date + i + 1, value]
        end.to_h
      end

      def source_time_series
        raise NoMethodError, 'must be implemented in a subclass'
      end

      private

      attr_reader :end_date

      def fill_missing_values!(metrics, from:, to:)
        current_date = from
        while current_date <= to
          metrics[current_date] ||= 0
          current_date += 1
        end

        metrics.sort.to_h
      end

      def good_fit?
        model && model.r2_score >= MINIMAL_SCORE_THRESHOLD
      end

      def model_forecast
        return [] unless model

        model.predict(horizon)
      end

      def model
        @model ||= Analytics::Forecasting::HoltWintersOptimizer.model_for(source_time_series.values)
      end
    end
  end
end
