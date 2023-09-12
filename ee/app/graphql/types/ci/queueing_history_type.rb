# frozen_string_literal: true

module Types
  module Ci
    class QueueingHistoryType < BaseObject
      graphql_name 'QueueingDelayHistory'
      description 'Aggregated statistics about queueing times for CI jobs'

      authorize :read_jobs_statistics

      field :time_series,
        [Types::Ci::QueueingHistoryTimeSeriesType],
        null: true,
        description: 'Time series.'
    end
  end
end
