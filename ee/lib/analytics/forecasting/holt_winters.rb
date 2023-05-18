# frozen_string_literal: true

module Analytics
  module Forecasting
    # Implements Holt-Winters triple exponential additive smoothing algorithm.
    class HoltWinters
      NotEnoughDataError = Class.new(StandardError)

      # See https://en.wikipedia.org/wiki/Coefficient_of_determination
      def self.r2_score(real, forecast)
        errors = real.map.with_index { |v, i| v - forecast[i] if v && forecast[i] }

        values = real.select.with_index { |_v, i| errors[i].present? }
        average = values.sum / values.size.to_f

        sst = values.sum { |v| (v - average)**2 }

        return 1.0 if sst == 0

        ssr = errors.compact.sum { |e| e**2 }

        1.0 - (ssr / sst)
      end

      attr_reader :time_series, :alpha, :beta, :gamma, :season

      # See https://robjhyndman.com/hyndsight/hw-initialization/ for algorithm formulas.
      # @param time_series, array of float values
      # @param alpha, float, level smoothing param
      # @param beta, float, trend smoothing param
      # @param gamma, float, seasonality smoothing param
      # @param season, integer, season size in data points
      def initialize(time_series, alpha:, beta:, gamma:, season:)
        if time_series.size < 2 * season
          raise NotEnoughDataError, "Time series size must be at least twice as season size"
        end

        @time_series = time_series
        @alpha = alpha.to_f
        @beta = beta.to_f
        @gamma = gamma.to_f
        @season = season.to_f
        @regression = Array.new(season)
        @l = Array.new(season, initial_level)
        @b = Array.new(season, initial_trend)
        @s = initial_seasonal_indexes

        calculate
      end

      # @param horizon, Integer, number of data points to predict
      def predict(horizon)
        Array.new(horizon) { |i| forecast_value(i) }
      end

      def r2_score
        self.class.r2_score(time_series, @regression)
      end

      private

      def calculate
        i = @s.size
        while i < time_series.size
          @regression[i] = forecast_value

          @l[i] = level_component(i)
          @b[i] = trend_component(i)
          @s[i] = seasonality_component(i)
          i += 1
        end
      end

      def forecast_value(offset = 0)
        level = @l.last
        trend = (offset + 1) * @b.last
        seasonality = @s[-season + (offset % season)]

        level + trend + seasonality
      end

      def initial_level
        @initial_level ||= time_series.first(season).sum / season
      end

      def initial_trend
        season.to_i.times.sum { |i| (time_series[season + i] - time_series[i]) } / (season**2)
      end

      def initial_seasonal_indexes
        time_series.first(season).map { |v| v - initial_level }
      end

      def level_component(index)
        (alpha * (time_series[index] - @s[index - season])) + ((1 - alpha) * (@l[index - 1] + @b[index - 1]))
      end

      def trend_component(index)
        (beta * (@l[index] - @l[index - 1])) + ((1 - beta) * @b[index - 1])
      end

      def seasonality_component(index)
        (gamma * (time_series[index] - @l[index - 1] - @b[index - 1])) + ((1 - gamma) * @s[index - season])
      end
    end
  end
end
