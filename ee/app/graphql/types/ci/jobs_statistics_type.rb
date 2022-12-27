# frozen_string_literal: true

module Types
  module Ci
    class JobsStatisticsType < GraphQL::Schema::Object
      graphql_name 'CiJobsStatistics'
      description 'Statistics for a group of CI jobs.'

      field :queued_duration, JobsDurationStatisticsType,
            null: true, description: %q(Statistics for time that jobs spent waiting to be picked up.)

      def queued_duration
        object.object[:queued_duration]
      end
    end
  end
end
