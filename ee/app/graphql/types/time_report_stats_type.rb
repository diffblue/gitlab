# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes
  class TimeReportStatsType < BaseObject
    graphql_name 'TimeReportStats'
    description 'Represents the time report stats for timeboxes'

    field :complete, ::Types::TimeboxMetricsType,
      null: true, description: 'Completed issues metrics.'

    field :incomplete, ::Types::TimeboxMetricsType,
      null: true, description: 'Incomplete issues metrics.'

    field :total, ::Types::TimeboxMetricsType,
      null: true, description: 'Total issues metrics.' end
end
