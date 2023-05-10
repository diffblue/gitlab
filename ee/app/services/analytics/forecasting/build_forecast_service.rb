# frozen_string_literal: true

module Analytics
  module Forecasting
    class BuildForecastService
      include BaseServiceUtility

      attr_reader :type, :context, :horizon

      HORIZON_LIMIT = 90
      SUPPORTED_TYPES = %w[deployment_frequency].freeze

      def initialize(type:, context:, horizon:)
        @type = type
        @context = context
        @horizon = horizon
      end

      def execute
        error = validate
        return error if error

        success(forecast: Forecast.for(type).new(type: type, context: context, horizon: horizon))
      end

      private

      def validate
        unless SUPPORTED_TYPES.include?(type)
          return error(
            format(_("Unsupported forecast type. Supported types: %{types}"), types: SUPPORTED_TYPES),
            :bad_request)
        end

        validate_deployment_frequency
      end

      def validate_deployment_frequency
        if horizon > HORIZON_LIMIT
          return error(
            format(_("Forecast horizon must be %{max_horizon} days at the most."), max_horizon: HORIZON_LIMIT),
            :bad_request)
        end

        return if context.is_a?(Project)

        error(_("Invalid context. Project is expected."), :bad_request)
      end
    end
  end
end
