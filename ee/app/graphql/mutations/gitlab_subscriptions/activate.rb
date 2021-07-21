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
            description: 'The current license.'

      def resolve(activation_code:)
        authorize! :global

        result = ::GitlabSubscriptions::ActivateService.new.execute(activation_code)

        { errors: Array(result[:errors]), license: result[:license] }
      end
    end
  end
end
