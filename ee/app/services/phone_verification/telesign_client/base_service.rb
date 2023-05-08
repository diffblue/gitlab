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

      def log_telesign_response(event, response, status_code)
        telesign_response = telesign_error_message(response) || telesign_status(response) || ''

        ::Gitlab::AppJsonLogger.info(
          class: self.class.name,
          message: 'IdentityVerification::Phone',
          event: event,
          telesign_response: telesign_response,
          telesign_status_code: status_code,
          username: user&.username
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

      def telesign_error
        error_message = s_('PhoneVerification|Something went wrong. Please try again.')
        error(error_message, :unknown_telesign_error)
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

      private

      def telesign_error_message(response)
        return unless response['errors'].present?

        error = response['errors'].first
        "error_message: #{error['description']}, error_code: #{error['code']}"
      end

      def telesign_status(response)
        response.dig('status', 'description')
      end
    end
  end
end
