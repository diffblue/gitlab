# frozen_string_literal: true

module Types
  module Ci
    class JobsDurationStatisticsType < GraphQL::Schema::Object
      graphql_name 'CiJobsDurationStatistics'
      description 'Representation of duration statistics for a group of CI jobs.'

      PERCENTILES = [50, 75, 90, 95, 99].freeze

      PERCENTILES.each do |p|
        field "p#{p}", Types::DurationType,
              null: true, description: "#{p}th percentile. #{p}% of the durations are lower than this value."

        define_method("p#{p}") do
          object["p#{p}".to_sym]
        end
      end
    end
  end
end
