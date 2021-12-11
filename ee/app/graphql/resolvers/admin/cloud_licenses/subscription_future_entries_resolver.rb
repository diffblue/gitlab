# frozen_string_literal: true

module Resolvers
  module Admin
    module CloudLicenses
      class SubscriptionFutureEntriesResolver < BaseResolver
        include Gitlab::Graphql::Authorize::AuthorizeResource

        type [::Types::Admin::CloudLicenses::SubscriptionFutureEntryType], null: true

        def resolve
          authorize!

          ::Gitlab::CurrentSettings.future_subscriptions.each do |subscription|
            subscription['type'] = subscription['cloud_license_enabled'] ? License::CLOUD_LICENSE_TYPE : License::LICENSE_FILE_TYPE
          end
        end

        private

        def authorize!
          Ability.allowed?(context[:current_user], :read_licenses) || raise_resource_not_available_error!
        end
      end
    end
  end
end
