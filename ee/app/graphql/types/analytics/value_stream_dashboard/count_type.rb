# frozen_string_literal: true

module Types
  module Analytics
    module ValueStreamDashboard
      # rubocop: disable Graphql/AuthorizeTypes
      class CountType < BaseObject
        graphql_name 'ValueStreamDashboardCount'
        description 'Represents a recorded measurement (object count) for the requested group'

        field :recorded_at, Types::TimeType, null: true,
          description: 'Time the measurement was taken.'

        field :count, GraphQL::Types::Int, null: true,
          description: 'Object count.'

        field :identifier,
          Types::Analytics::ValueStreamDashboard::MetricEnum,
          null: false,
          description: 'Type of object being measured.'
      end
      # rubocop: enable Graphql/AuthorizeTypes
    end
  end
end
