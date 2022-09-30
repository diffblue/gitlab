# frozen_string_literal: true

module Arkose
  class Logger
    attr_reader :session_token, :user, :response

    def initialize(session_token:, user: nil, verify_response: nil)
      @session_token = session_token
      @user = user
      @response = verify_response
    end

    def log_successful_token_verification
      return unless response

      logger.info(build_message('Arkose verify response'))
    end

    def log_unsolved_challenge
      return unless response

      logger.info(build_message('Challenge was not solved'))
    end

    def log_failed_token_verification
      payload = {
        session_token: session_token,
        log_data: user&.id
      }

      logger.error("Error verifying user on Arkose: #{payload}")
    end

    private

    def logger
      Gitlab::AppLogger
    end

    def build_message(message)
      Gitlab::ApplicationContext.current.symbolize_keys.merge(
        {
          message: message,
          response: response.response,
          username: user&.username
        }.compact).merge(arkose_payload)
    end

    def arkose_payload
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
  end
end
