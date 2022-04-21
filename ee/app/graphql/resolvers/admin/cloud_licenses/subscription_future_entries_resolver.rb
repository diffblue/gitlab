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
            subscription['type'] = if subscription['offline_cloud_licensing'] && subscription['cloud_license_enabled']
                                     License::OFFLINE_CLOUD_TYPE
                                   elsif subscription['cloud_license_enabled'] && !subscription['offline_cloud_licensing']
                                     License::ONLINE_CLOUD_TYPE
                                   else
                                     License::LEGACY_LICENSE_TYPE
                                   end
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
