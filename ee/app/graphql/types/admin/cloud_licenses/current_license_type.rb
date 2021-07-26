# frozen_string_literal: true

module Types
  module Admin
    module CloudLicenses
      # rubocop: disable Graphql/AuthorizeTypes
      class CurrentLicenseType < BaseObject
        include ::Types::Admin::CloudLicenses::LicenseType

        graphql_name 'CurrentLicense'
        description 'Represents the current license'

        field :last_sync, ::Types::TimeType, null: true,
              description: 'Date when the license was last synced.',
              method: :last_synced_at

        field :billable_users_count, GraphQL::Types::Int, null: true,
              description: 'Number of billable users on the system.',
              method: :daily_billable_users_count

        field :maximum_user_count, GraphQL::Types::Int, null: true,
              description: 'Highest number of billable users on the system during the term of the current license.',
              method: :maximum_user_count

        field :users_over_license_count, GraphQL::Types::Int, null: true,
              description: 'Number of users over the paid users in the license.'

        def users_over_license_count
          return 0 if object.trial?

          [object.overage_with_historical_max, 0].max
        end
      end
    end
  end
end
