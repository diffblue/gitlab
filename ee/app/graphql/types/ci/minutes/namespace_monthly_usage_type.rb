# frozen_string_literal: true

module Types
  module Ci
    module Minutes
      # rubocop: disable Graphql/AuthorizeTypes
      # this type only exposes data related to the current user
      class NamespaceMonthlyUsageType < BaseObject
        graphql_name 'CiMinutesNamespaceMonthlyUsage'

        field :month, ::GraphQL::STRING_TYPE, null: true,
              description: 'The month related to the usage data.'

        field :minutes, ::GraphQL::INT_TYPE, null: true,
              method: :amount_used,
              description: 'The total number of minutes used by all projects in the namespace.'

        field :projects, ::Types::Ci::Minutes::ProjectMonthlyUsageType.connection_type, null: true,
              description: 'CI minutes usage data for projects in the namespace.'

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
