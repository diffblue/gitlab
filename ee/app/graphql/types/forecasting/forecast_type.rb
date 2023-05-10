# frozen_string_literal: true

module Types
  module Forecasting
    class ForecastType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'Forecast'
      description 'Information about specific forecast created'

      field :status, Types::Forecasting::ForecastStatusEnum, null: false, description: "Status of the forecast."

      field :values, Types::Forecasting::DatapointType.connection_type, null: true,
        description: 'Actual forecast values.'

      def values
        object.values.to_a
      end

      def status
        object.status.to_s.upcase
      end
    end
  end
end
