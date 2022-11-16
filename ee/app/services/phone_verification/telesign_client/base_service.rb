# frozen_string_literal: true

module PhoneVerification
  module TelesignClient
    class BaseService
      attr_reader :user

      # BACF - for creating an account where the service may be vulnerable to bulk attacks and fraudsters
      USE_CASE_ID = 'BACF'

      HTTP_SUCCESS = '200'
      HTTP_CLIENT_ERROR = '400'

      def execute
        raise NotImplementedError
      end

      def log_telesign_response(message, response, status_code)
        ::Gitlab::AppJsonLogger.info(
          message: message,
          telesign_response: response,
          telesign_status_code: status_code,
          user_id: user.id
        )
      end

      def invalid_phone_number_error
        error_message = s_(
          'PhoneVerification|There was a problem with the phone number you entered. '\
          'Enter a valid phone number.'
        )
        error(error_message, :invalid_phone_number)
      end

      def success(payload)
        ServiceResponse.success(
          payload: payload
        )
      end

      def error(error_message, reason)
        ServiceResponse.error(
          message: error_message,
          reason: reason
        )
      end

      def generic_error
        error_message = s_('PhoneVerification|Something went wrong. Please try again.')
        error(error_message, :internal_server_error)
      end

      def track_exception(error)
        Gitlab::ErrorTracking.track_exception(error, user_id: user.id)
      end

      def customer_id
        @customer_id ||= ::Gitlab::CurrentSettings.telesign_customer_xid || ENV['TELESIGN_CUSTOMER_XID']
      end

      def api_key
        @api_key ||= ::Gitlab::CurrentSettings.telesign_api_key || ENV['TELESIGN_API_KEY']
      end
    end
  end
end
