# frozen_string_literal: true

module Arkose
  class TokenVerificationService
    attr_reader :session_token, :user

    ARKOSE_LABS_DEFAULT_NAMESPACE = 'client'
    ARKOSE_LABS_DEFAULT_SUBDOMAIN = 'verify-api'

    def initialize(session_token:, user: nil)
      @session_token = session_token
      @user = user
    end

    def execute
      response = Gitlab::HTTP.perform_request(Net::HTTP::Post, arkose_verify_url, body: body).parsed_response
      response = ::Arkose::VerifyResponse.new(response)

      logger.info(build_message(response))

      return ServiceResponse.error(message: response.error) if response.invalid_token?

      RecordUserDataService.new(response: response, user: user).execute

      if response.allowlisted? || response.challenge_solved?
        payload = {
          low_risk: response.allowlisted? || response.low_risk?,
          response: response
        }
        ServiceResponse.success(payload: payload)
      else
        ServiceResponse.error(message: 'Captcha was not solved')
      end
    rescue StandardError => error
      payload = {
        # Allow user to proceed when we can't verify the token for some
        # unexpected reason (e.g. ArkoseLabs is down)
        low_risk: true,
        session_token: session_token,
        log_data: user&.id
      }.compact
      Gitlab::ExceptionLogFormatter.format!(error, payload)
      Gitlab::ErrorTracking.track_exception(error)
      logger.error("Error verifying user on Arkose: #{payload}")

      ServiceResponse.success(payload: payload)
    end

    private

    def body
      {
        private_key: Settings.arkose_private_api_key,
        session_token: session_token,
        log_data: user&.id
      }.compact
    end

    def logger
      Gitlab::AppLogger
    end

    def build_message(response)
      Gitlab::ApplicationContext.current.symbolize_keys.merge(
        {
          message: 'Arkose verify response',
          response: response.response,
          username: user&.username
        }.compact).merge(arkose_payload(response))
    end

    def arkose_payload(response)
      {
        'arkose.session_id': response.session_id,
        'arkose.global_score': response.global_score,
        'arkose.global_telltale_list': response.global_telltale_list,
        'arkose.custom_score': response.custom_score,
        'arkose.custom_telltale_list': response.custom_telltale_list,
        'arkose.risk_band': response.risk_band,
        'arkose.risk_category': response.risk_category
      }
    end

    def arkose_verify_url
      arkose_labs_namespace = ::Gitlab::CurrentSettings.arkose_labs_namespace
      subdomain = if arkose_labs_namespace == ARKOSE_LABS_DEFAULT_NAMESPACE
                    ARKOSE_LABS_DEFAULT_SUBDOMAIN
                  else
                    "#{arkose_labs_namespace}-verify"
                  end

      "https://#{subdomain}.arkoselabs.com/api/v4/verify/"
    end
  end
end
