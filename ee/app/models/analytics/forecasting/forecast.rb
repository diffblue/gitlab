# frozen_string_literal: true

module Analytics
  module Forecasting
    class Forecast
      include ActiveModel::Model

      MINIMAL_SCORE_THRESHOLD = 0.4

      attr_accessor :context, :type, :horizon

      class << self
        def declarative_policy_class
          'Analytics::Forecasting::ForecastPolicy'
        end

        def for(type)
          return unless type == 'deployment_frequency'

          DeploymentFrequencyForecast
        end

        def context_class
          raise NoMethodError, 'must be implemented in a subclass'
        end
      end

      def initialize(*)
        super

        raise 'Invalid context class.' unless context.class <= self.class.context_class

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
