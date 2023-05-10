# frozen_string_literal: true

module Analytics
  module Forecasting
    class BuildForecastService
      include BaseServiceUtility

      attr_reader :type, :context, :horizon

      HORIZON_LIMIT = 90

      class << self
        include BaseServiceUtility

        def validate(type:, context_class:, horizon:)
          forecast_class = Forecast.for(type)

          validate_forecast_class(forecast_class) ||
            validate_context_class(forecast_class, context_class) ||
            validate_horizon(horizon)
        end

        private

        def validate_forecast_class(forecast_class)
          error(_("Unsupported forecast type."), :bad_request) unless forecast_class
        end

        def validate_horizon(horizon)
          return unless horizon > HORIZON_LIMIT || horizon <= 0

          error(
            format(_("Forecast horizon must be positive and %{max_horizon} days at the most."),
              max_horizon: HORIZON_LIMIT),
            :bad_request)
        end

        def validate_context_class(forecast_class, context_class)
          return if context_class <= forecast_class.context_class

          error(
            format(_("Invalid context type. %{type} is expected."), type: forecast_class.context_class),
            :bad_request)
        end
      end

      def initialize(type:, context:, horizon:)
        @type = type
        @context = context
        @horizon = horizon
      end

      def execute
        error = self.class.validate(type: type, context_class: context.class, horizon: horizon)
        return error if error

        success(forecast: forecast)
      end

      def forecast
        @forecast ||= Forecast.for(type).new(type: type, context: context, horizon: horizon)
      end
    end
  end
end
