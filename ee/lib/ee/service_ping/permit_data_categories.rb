# frozen_string_literal: true

module EE
  module ServicePing
    module PermitDataCategories
      extend ::Gitlab::Utils::Override

      STANDARD_CATEGORY = ::ServicePing::PermitDataCategories::STANDARD_CATEGORY
      SUBSCRIPTION_CATEGORY = ::ServicePing::PermitDataCategories::SUBSCRIPTION_CATEGORY
      OPTIONAL_CATEGORY = ::ServicePing::PermitDataCategories::OPTIONAL_CATEGORY
      OPERATIONAL_CATEGORY = ::ServicePing::PermitDataCategories::OPERATIONAL_CATEGORY

      override :execute
      def execute
        return super unless ::License.current.present?
        return super unless ::ServicePing::ServicePingSettings.product_intelligence_enabled?

        optional_enabled = ::Gitlab::CurrentSettings.usage_ping_enabled?
        customer_service_enabled = ::License.current.customer_service_enabled?

        [STANDARD_CATEGORY, SUBSCRIPTION_CATEGORY].tap do |categories|
          categories << OPERATIONAL_CATEGORY << OPTIONAL_CATEGORY if optional_enabled
          categories << OPERATIONAL_CATEGORY if customer_service_enabled
        end.to_set
      end
    end
  end
end
