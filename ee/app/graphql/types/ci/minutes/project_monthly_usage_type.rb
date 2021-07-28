# frozen_string_literal: true

module Types
  module Ci
    module Minutes
      # rubocop: disable Graphql/AuthorizeTypes
      # this type only exposes data related to the current user
      class ProjectMonthlyUsageType < BaseObject
        graphql_name 'CiMinutesProjectMonthlyUsage'

        field :minutes, ::GraphQL::INT_TYPE, null: true,
              method: :amount_used,
              description: 'The number of CI minutes used by the project in the month.'

        field :name, ::GraphQL::STRING_TYPE, null: true,
              description: 'The name of the project.'

        def name
          object.project.name
        end
      end
    end
  end
end
