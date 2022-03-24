# frozen_string_literal: true
module Arkose
  class UserVerificationService
    attr_reader :url, :session_token, :userid

    VERIFY_URL = 'http://verify-api.arkoselabs.com/api/v4/verify'

    def initialize(session_token:, userid:)
      @session_token = session_token
      @userid = userid
    end

    def execute
      response = Gitlab::HTTP.perform_request(Net::HTTP::Post, VERIFY_URL, body: body)
      logger.info(build_message("Arkose verify response: #{response.parsed_response}"))

      return false if invalid_token(response)

      challenge_solved?(response) && low_risk?(response)
    rescue StandardError => error
      payload = { session_token: session_token, log_data: userid }
      Gitlab::ExceptionLogFormatter.format!(error, payload)
      Gitlab::ErrorTracking.track_exception(error)
      logger.error(build_message("Error verifying user on Arkose: #{payload}"))

      true
    end

    private

    def body
      {
        private_key: Settings.arkose['private_key'],
        session_token: session_token,
        log_data: userid
      }
    end

    def logger
      Gitlab::AppLogger
    end

    def build_message(message)
      Gitlab::ApplicationContext.current.merge(message: message)
    end

    def invalid_token(response)
      response.parsed_response&.key?('error')
    end

    def challenge_solved?(response)
      solved = response.parsed_response&.dig('session_details', 'solved')
      solved.nil? ? true : solved
    end

    def low_risk?(response)
      risk_band = response.parsed_response&.dig('session_risk', 'risk_band')
      risk_band.present? ? risk_band != 'High' : true
    end
  end
end
