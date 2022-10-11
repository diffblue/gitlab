# frozen_string_literal: true

module Mutations
  module GitlabSubscriptions
    class Activate < BaseMutation
      graphql_name 'GitlabSubscriptionActivate'

      authorize :manage_subscription

      argument :activation_code, GraphQL::Types::String,
               required: true,
               description: 'Activation code received after purchasing a GitLab subscription.'

      field :license, Types::Admin::CloudLicenses::CurrentLicenseType,
            null: true,
            description: 'Current license.'

      field :future_subscriptions, [::Types::Admin::CloudLicenses::SubscriptionFutureEntryType],
            null: true,
            description: 'Array of future subscriptions.'

      def resolve(activation_code:)
        authorize! :global

        result = ::GitlabSubscriptions::ActivateService.new.execute(activation_code)

        {
          errors: Array(result[:errors]),
          license: result[:license],
          future_subscriptions: Array(result[:future_subscriptions])
        }
      end
    end
  end
end
