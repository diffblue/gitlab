# frozen_string_literal: true

module Types
  module Ci
    module Minutes
      # rubocop: disable Graphql/AuthorizeTypes
      # this type only exposes data related to the current user
      class NamespaceMonthlyUsageType < BaseObject
        graphql_name 'CiMinutesNamespaceMonthlyUsage'
        authorize :read_usage

        field :month, ::GraphQL::Types::String, null: true,
                                                description: 'Month related to the usage data.'

        field :month_iso8601,
              ::GraphQL::Types::ISO8601Date,
              method: :date,
              null: true,
              description: 'Month related to the usage data in ISO 8601 date format.'

        field :minutes,
              ::GraphQL::Types::Int,
              null: true,
              method: :amount_used,
              description: 'Total number of minutes used by all projects in the namespace.'

        field :projects,
              ::Types::Ci::Minutes::ProjectMonthlyUsageType.connection_type,
              null: true,
              description: 'CI/CD minutes usage data for projects in the namespace.'

        field :shared_runners_duration,
              ::GraphQL::Types::Int,
              null: true,
              description: 'Total duration (in seconds) of shared runners use by the namespace for the month.'

        def month
          object.date.strftime('%B')
        end

        def projects
          ::Ci::Minutes::ProjectMonthlyUsage.for_namespace_monthly_usage(object)
        end
      end
    end
  end
end
