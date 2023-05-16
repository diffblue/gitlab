# frozen_string_literal: true

module PhoneVerification
  module TelesignClient
    class SendVerificationCodeService < BaseService
      # TeleSign API: https://developer.telesign.com/enterprise/reference/sendsmsverifycode

      SMS_TEMPLATE = 'Your GitLab verification code is $$CODE$$. This code will expire in 5 minutes.'

      def initialize(phone_number:, user:)
        @phone_number = phone_number
        @user = user
      end

      def execute
        verify_client = TelesignEnterprise::VerifyClient.new(customer_id, api_key)
        response = verify_client.sms(phone_number, ucid: USE_CASE_ID, template: SMS_TEMPLATE)

        json_response = response.json
        request_status = response.status_code

        log_telesign_response(
          'Sent a phone verification code with Telesign',
          json_response,
          request_status
        )

        telesign_reference_xid = json_response['reference_id']

        case request_status
        when HTTP_SUCCESS then send_success(telesign_reference_xid)
        when HTTP_CLIENT_ERROR then invalid_phone_number_error
        else
          telesign_error
        end

      rescue URI::InvalidURIError
        invalid_phone_number_error
      rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
        telesign_error
      rescue StandardError => e
        track_exception(e)
        generic_error
      end

      private

      attr_reader :phone_number

      def send_success(telesign_reference_xid)
        success({ telesign_reference_xid: telesign_reference_xid })
      end
    end
  end
end
