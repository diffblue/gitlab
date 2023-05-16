# frozen_string_literal: true

module PhoneVerification
  module TelesignClient
    class VerifyCodeService < BaseService
      # TeleSign API: https://developer.telesign.com/enterprise/reference/sendsmsverifycode

      VALID = 'VALID'
      INVALID = 'INVALID'
      EXPIRED = 'EXPIRED'
      MAX_ATTEMPTS_EXCEEDED = 'MAX_ATTEMPTS_EXCEEDED'

      def initialize(telesign_reference_xid:, verification_code:, user:)
        @telesign_reference_xid = telesign_reference_xid
        @verification_code = verification_code
        @user = user
      end

      def execute
        verify_client = TelesignEnterprise::VerifyClient.new(customer_id, api_key)
        response = verify_client.status(telesign_reference_xid, verify_code: verification_code)

        json_response = response.json
        request_status = response.status_code

        log_telesign_response(
          'Verified a phone verification code with Telesign',
          json_response,
          request_status
        )

        if request_status == HTTP_SUCCESS
          code_state = json_response['verify']['code_state']
          code_state == VALID ? verify_success : invalid_code_error(code_state)
        else
          telesign_error
        end

      rescue Timeout::Error, Errno::ECONNREFUSED, Errno::EHOSTUNREACH, SocketError
        telesign_error
      rescue StandardError => e
        track_exception(e)
        generic_error
      end

      private

      attr_reader :telesign_reference_xid, :verification_code

      def verify_success
        success({ telesign_reference_xid: telesign_reference_xid })
      end

      def invalid_code_error(code_state)
        error_responses = {
          INVALID => s_('PhoneVerification|Enter a valid code.'),
          EXPIRED => s_('PhoneVerification|The code has expired. Request a new code and try again.'),
          MAX_ATTEMPTS_EXCEEDED => s_(
            'PhoneVerification|You\'ve reached the maximum number of tries. Request a new code and try again.'
          )
        }

        generic_error_message = s_('PhoneVerification|Something went wrong. Please try again.')

        error_message = error_responses[code_state] || generic_error_message
        error(error_message, :invalid_code)
      end
    end
  end
end
