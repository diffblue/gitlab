# frozen_string_literal: true

module EE
  module Types
    module Ci
      module RunnerCountableConnectionType
        extend ActiveSupport::Concern

        prepended do
          field :jobs_statistics, ::Types::Ci::JobsStatisticsType,
                null: true,
                resolver: ::Resolvers::Ci::RunnersJobsStatisticsResolver,
                extras: [:lookahead]
        end
      end
    end
  end
end
