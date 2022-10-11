# frozen_string_literal: true

module Types
  module Admin
    module CloudLicenses
      # rubocop: disable Graphql/AuthorizeTypes
      class SubscriptionFutureEntryType < BaseObject
        graphql_name 'SubscriptionFutureEntry'
        description 'Represents an entry from the future subscriptions'

        field :type, GraphQL::Types::String,
          null: false, description: 'Type of license the subscription will yield.'

        field :plan, GraphQL::Types::String,
          null: false, description: 'Name of the subscription plan.'

        field :name, GraphQL::Types::String,
          null: true, description: 'Name of the licensee.'

        field :email, GraphQL::Types::String,
          null: true, description: 'Email of the licensee.'

        field :company, GraphQL::Types::String,
          null: true, description: 'Company of the licensee.'

        field :starts_at, ::Types::DateType,
          null: true, description: 'Date when the license started.'

        field :expires_at, ::Types::DateType,
          null: true, description: 'Date when the license expires.'

        field :users_in_license_count, GraphQL::Types::Int,
          null: true, description: 'Number of paid user seats.'

        def type
          if object['offline_cloud_licensing'] && object['cloud_license_enabled']
            License::OFFLINE_CLOUD_TYPE
          elsif object['cloud_license_enabled'] && !object['offline_cloud_licensing']
            License::ONLINE_CLOUD_TYPE
          else
            License::LEGACY_LICENSE_TYPE
          end
        end
      end
    end
  end
end
