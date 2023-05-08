# frozen_string_literal: true

module PhoneVerification
  module Users
    class SendVerificationCodeService
      include ActionView::Helpers::DateHelper

      TELESIGN_ERROR = :unknown_telesign_error

      def initialize(user, params = {})
        @user = user
        @params = params

        @record = ::Users::PhoneNumberValidation.for_user(user.id).first_or_initialize
        @record.assign_attributes(params)
      end

      def execute
        return error_in_params unless valid?
        return error_rate_limited if rate_limited?
        return error_high_risk_number if related_to_banned_user?

        risk_result = ::PhoneVerification::TelesignClient::RiskScoreService.new(
          phone_number: phone_number,
          user: user
        ).execute

        return error_downstream_service(risk_result) unless risk_result.success?

        send_code_result = ::PhoneVerification::TelesignClient::SendVerificationCodeService.new(
          phone_number: phone_number,
          user: user
        ).execute

        return error_downstream_service(send_code_result) unless send_code_result.success?

        success(risk_result, send_code_result)

      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, user_id: user.id)
        error
      end

      private

      attr_reader :user, :params, :record

      def phone_number
        params[:international_dial_code].to_s + params[:phone_number].to_s
      end

      def valid?
        record.valid?
      end

      def rate_limited?
        ::Gitlab::ApplicationRateLimiter.throttled?(:phone_verification_send_code, scope: user)
      end

      def related_to_banned_user?
        ::Users::PhoneNumberValidation.related_to_banned_user?(
          params[:international_dial_code], params[:phone_number]
        )
      end

      def error_in_params
        ServiceResponse.error(
          message: record.errors.first.full_message,
          reason: :bad_params
        )
      end

      def error_rate_limited
        interval_in_seconds = ::Gitlab::ApplicationRateLimiter.rate_limits[:phone_verification_send_code][:interval]
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

      def error_high_risk_number
        ServiceResponse.error(
          message: s_(
            'PhoneVerification|There was a problem with the phone number you entered. '\
            'Enter a different phone number and try again.'
          ),
          reason: :related_to_banned_user
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
          risk_score: 0,
          telesign_reference_xid: TELESIGN_ERROR.to_s,
          validated_at: Time.now.utc
        )
      end

      def success(risk_result, send_code_result)
        record.update!(
          risk_score: risk_result[:risk_score],
          telesign_reference_xid: send_code_result[:telesign_reference_xid]
        )

        ServiceResponse.success
      end
    end
  end
end
