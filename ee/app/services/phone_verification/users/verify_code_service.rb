# frozen_string_literal: true

module PhoneVerification
  module Users
    class VerifyCodeService
      include ActionView::Helpers::DateHelper

      TELESIGN_ERROR = :unknown_telesign_error

      def initialize(user, params = {})
        @user = user
        @params = params

        @record = ::Users::PhoneNumberValidation.for_user(user.id).first
      end

      def execute
        return error_in_params unless valid?
        return error_rate_limited if rate_limited?

        verify_result = ::PhoneVerification::TelesignClient::VerifyCodeService.new(
          telesign_reference_xid: record.telesign_reference_xid,
          verification_code: verification_code,
          user: user
        ).execute

        return error_downstream_service(verify_result) unless verify_result.success?

        success

      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, user_id: user.id)
        error
      end

      private

      attr_reader :user, :params, :record

      def verification_code
        params[:verification_code].to_s
      end

      def valid?
        params[:verification_code].present?
      end

      def rate_limited?
        ::Gitlab::ApplicationRateLimiter.throttled?(:phone_verification_verify_code, scope: user)
      end

      def error_in_params
        ServiceResponse.error(
          message: s_('PhoneVerification|Verification code can\'t be blank.'),
          reason: :bad_params
        )
      end

      def error_rate_limited
        interval_in_seconds = ::Gitlab::ApplicationRateLimiter.rate_limits[:phone_verification_verify_code][:interval]
        interval = distance_of_time_in_words(interval_in_seconds)

        ServiceResponse.error(
          message: format(
            s_(
              'PhoneVerification|You\'ve reached the maximum number of tries. '\
              'Wait %{interval} and try again.'
            ),
            interval: interval
          ),
          reason: :rate_limited
        )
      end

      def error_downstream_service(result)
        force_verify if result.reason == TELESIGN_ERROR

        ServiceResponse.error(
          message: result.message,
          reason: result.reason
        )
      end

      def error
        ServiceResponse.error(
          message: s_('PhoneVerification|Something went wrong. Please try again.'),
          reason: :internal_server_error
        )
      end

      def force_verify
        record.update!(
          telesign_reference_xid: TELESIGN_ERROR.to_s,
          validated_at: Time.now.utc
        )
      end

      def success
        record.update!(
          validated_at: Time.now.utc
        )

        ServiceResponse.success
      end
    end
  end
end
