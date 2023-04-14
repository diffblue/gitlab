# frozen_string_literal: true

module PhoneVerification
  module TelesignClient
    class RiskScoreService < BaseService
      # TeleSign API: https://developer.telesign.com/enterprise/reference/submitphonenumberforintelligence

      # High risk: https://developer.telesign.com/enterprise/docs/codes-languages-and-time-zones#phone-type-codes
      BLOCKED_PHONE_TYPES = %w[TOLL_FREE PAGER VOIP INVALID OTHER VOICEMAIL RESTRICTED_PREMIUM PAYPHONE].freeze

      def initialize(phone_number:, user:)
        @phone_number = phone_number
        @user = user
      end

      def execute
        phoneid_client = TelesignEnterprise::PhoneIdClient.new(customer_id, api_key)
        response = phoneid_client.score(phone_number, USE_CASE_ID, request_risk_insights: true)

        json_response = response.json
        request_status = response.status_code

        log_telesign_response(
          'Received a risk score for a phone number from Telesign',
          json_response,
          request_status
        )

        case request_status
        when HTTP_SUCCESS
          phone_type = json_response['phone_type']['description']
          risk_score = json_response['risk']['score']
          BLOCKED_PHONE_TYPES.include?(phone_type) ? blocked : risk_success(risk_score)
        when HTTP_CLIENT_ERROR
          invalid_phone_number_error
        else
          telesign_error
        end

      rescue URI::InvalidURIError
        invalid_phone_number_error
      rescue StandardError => e
        track_exception(e)
        generic_error
      end

      private

      attr_reader :phone_number

      def risk_success(risk_score)
        success({ risk_score: risk_score })
      end

      def blocked
        error_message = s_(
          'PhoneVerification|There was a problem with the phone number you entered. '\
          'Enter a different phone number and try again.'
        )
        error(error_message, :invalid_phone_number)
      end
    end
  end
end
