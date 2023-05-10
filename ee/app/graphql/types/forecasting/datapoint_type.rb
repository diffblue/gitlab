# frozen_string_literal: true

module Types
  module Forecasting
    class DatapointType < BaseObject # rubocop:disable Graphql/AuthorizeTypes
      graphql_name 'ForecastDatapoint'
      description 'Information about specific forecast datapoint'

      field :datapoint, GraphQL::Types::String, null: false, description: 'Datapoint of the forecast. Usually a date.',
        method: :first
      field :value, GraphQL::Types::Float, null: true, description: 'Value of the given datapoint.', method: :last
    end
  end
end
