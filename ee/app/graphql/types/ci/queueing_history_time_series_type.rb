# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class QueueingHistoryTimeSeriesType < BaseObject
      graphql_name 'QueueingHistoryTimeSeries'
      description 'The amount of time for a job to be picked up by a runner, in percentiles.'

      PERCENTILES = [50, 75, 90, 95, 99].freeze

      field :time,
        Types::TimeType,
        null: false,
        description: 'Start of the time interval.'

      PERCENTILES.each do |p|
        field "p#{p}", Types::DurationType,
          null: true, description: "#{p}th percentile. #{p}% of the durations are lower than this value.",
          alpha: { milestone: '16.4' }
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
