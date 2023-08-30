# frozen_string_literal: true

module Resolvers
  module Analytics
    module ValueStreamDashboard
      class CountResolver < BaseResolver
        type ::Types::Analytics::ValueStreamDashboard::CountType, null: true

        include Gitlab::Graphql::Authorize::AuthorizeResource

        authorizes_object!
        authorize :read_group_analytics_dashboards

        argument :identifier, Types::Analytics::ValueStreamDashboard::MetricEnum,
          required: true,
          description: 'Type of counts to retrieve.'

        argument :timeframe, Types::TimeframeInputType,
          required: true,
          description: 'Counts recorded during this time frame, usually from beginning of ' \
                       'the month until the end of the month (the system runs monthly aggregations).'

        def resolve(identifier:, timeframe:)
          count, last_recorded_at = ::Analytics::ValueStreamDashboard::Count
            .aggregate_for_period(object, identifier.to_sym, timeframe[:start], timeframe[:end])

          return unless last_recorded_at

          {
            recorded_at: last_recorded_at,
            count: count,
            identifier: identifier
          }
        end
      end
    end
  end
end
