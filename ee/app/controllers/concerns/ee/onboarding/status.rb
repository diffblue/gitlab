# frozen_string_literal: true

module EE
  module Onboarding
    module Status
      extend ::Gitlab::Utils::Override

      override :continue_full_onboarding?
      def continue_full_onboarding?
        !subscription? &&
          !invite? &&
          !oauth? &&
          enabled?
      end

      def redirect_to_company_form?
        trial? || ::Gitlab::Utils.to_boolean(params.dig(:user, :setup_for_company), default: false)
      end

      def invite?
        members.any?
      end

      def trial?
        enabled? && ::Gitlab::Utils.to_boolean(params[:trial], default: false)
      end

      def oauth?
        return false unless base_stored_user_location_path.present?

        base_stored_user_location_path.starts_with?(::Gitlab::Routing.url_helpers.oauth_authorization_path)
      end

      def enabled?
        ::Gitlab.com?
      end

      def subscription?
        enabled? && base_stored_user_location_path == ::Gitlab::Routing.url_helpers.new_subscriptions_path
      end

      def iterable_product_interaction
        if invite?
          'Invited User'
        else
          'Personal SaaS Registration'
        end
      end

      def eligible_for_iterable_trigger?
        return false if trial?
        return true if invite?
        # skip company page because it already sends request to CustomersDot
        return false if redirect_to_company_form?

        # regular registration
        continue_full_onboarding?
      end

      def stored_user_location
        # side effect free look at devise store_location_for(:user)
        session['user_return_to']
      end

      private

      attr_reader :params, :session

      def base_stored_user_location_path
        return unless stored_user_location

        URI.parse(stored_user_location).path
      end
    end
  end
end
