# frozen_string_literal: true

module Types
  module Ci
    module Minutes
      # rubocop: disable Graphql/AuthorizeTypes
      # this type only exposes data related to the current user
      class ProjectMonthlyUsageType < BaseObject
        graphql_name 'CiMinutesProjectMonthlyUsage'

        field :minutes,
              ::GraphQL::Types::Int,
              null: true,
              method: :amount_used,
              description: 'Number of CI/CD minutes used by the project in the month.'

        field :shared_runners_duration,
              ::GraphQL::Types::Int,
              null: true,
              description: 'Total duration (in seconds) of shared runners use by the project for the month.'

        field :project,
              Types::ProjectType,
              null: true,
              description: 'Project having the recorded usage.'

        field :name,
              ::GraphQL::Types::String,
              null: true,
              deprecated: { reason: 'Use `project.name`', milestone: '15.6' },
              description: 'Name of the project.'

        def name
          object.project&.name
        end
      end
    end
  end
end
