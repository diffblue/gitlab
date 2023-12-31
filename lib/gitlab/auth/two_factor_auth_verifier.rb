# frozen_string_literal: true

module Gitlab
  module Auth
    class TwoFactorAuthVerifier
      attr_reader :current_user, :request

      def initialize(current_user, request = nil)
        @current_user = current_user
        @request = request
      end

      def two_factor_authentication_enforced?
        two_factor_authentication_required? && two_factor_grace_period_expired?
      end

      def two_factor_authentication_required?
        return false if allow_2fa_bypass_for_provider

        Gitlab::CurrentSettings.require_two_factor_authentication? ||
          current_user&.require_two_factor_authentication_from_group?
      end

      def current_user_needs_to_setup_two_factor?
        current_user && !current_user.temp_oauth_email? && !current_user.two_factor_enabled?
      end

      def two_factor_grace_period
        periods = [Gitlab::CurrentSettings.two_factor_grace_period]
        periods << current_user.two_factor_grace_period if current_user&.require_two_factor_authentication_from_group?
        periods.min
      end

      def two_factor_grace_period_expired?
        time = current_user&.otp_grace_period_started_at

        return false unless time

        two_factor_grace_period.hours.since(time) < Time.current
      end

      def allow_2fa_bypass_for_provider
        return false if Feature.disabled?(:by_pass_two_factor_for_current_session)

        request.session[:provider_2FA].present? if request
      end
    end
  end
end
