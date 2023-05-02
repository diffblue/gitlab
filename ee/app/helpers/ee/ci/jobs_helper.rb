# frozen_string_literal: true

module EE
  module Ci
    module JobsHelper
      extend ::Gitlab::Utils::Override

      override :jobs_data
      def jobs_data
        super.merge({
          "subscriptions_more_minutes_url" => ::Gitlab::Routing.url_helpers.subscription_portal_more_minutes_url
        })
      end
    end
  end
end
