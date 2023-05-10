# frozen_string_literal: true

module Types
  module Forecasting
    class ForecastStatusEnum < BaseEnum
      graphql_name 'ForecastStatus'
      description 'List of statuses for forecasting model.'

      value 'READY', description: 'Forecast is ready.'
      value 'UNAVAILABLE', description: 'Forecast is unavailable.'
    end
  end
end
