# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # this represents a hash, from the computed percentiles query
    class JobsStatisticsType < BaseObject
      graphql_name 'CiJobsStatistics'
      description 'Statistics for a group of CI jobs.'

      field :queued_duration, JobsDurationStatisticsType,
            null: true, description: %q(Statistics for amount of time that jobs were waiting to be picked up.),
            alpha: { milestone: '15.8' }

      def queued_duration
        object.object[:queued_duration]
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
