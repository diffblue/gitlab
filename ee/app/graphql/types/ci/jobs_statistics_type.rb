# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    # this represents a hash, from the computed percentiles query
    class JobsStatisticsType < BaseObject
      graphql_name 'CiJobsStatistics'
      description 'Statistics for a group of CI jobs.'

      field :queued_duration, JobsDurationStatisticsType,
            null: true,
            description:
              "Statistics for amount of time that jobs were waiting to be picked up. The calculation is performed " \
              "based on the most recent #{Resolvers::Ci::RunnersJobsStatisticsResolver::JOBS_LIMIT} jobs executed by " \
              "all the runners in context.",
            alpha: { milestone: '15.8' }

      def queued_duration
        object.object[:queued_duration]
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
