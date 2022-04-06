# frozen_string_literal: true
module Arkose
  class UserVerificationService
    attr_reader :url, :session_token, :user

    VERIFY_URL = 'http://verify-api.arkoselabs.com/api/v4/verify'
    ALLOWLIST_TELLTALE = 'gitlab1-whitelist-qa-team'

    def initialize(session_token:, user:)
      @session_token = session_token
      @user = user
    end

    def execute
      response = Gitlab::HTTP.perform_request(Net::HTTP::Post, VERIFY_URL, body: body).parsed_response
      logger.info(build_message("Arkose verify response: #{response}"))

      return false if invalid_token(response)

      add_or_update_arkose_attributes(response)

      allowlisted?(response) || (challenge_solved?(response) && low_risk?(response))
    rescue StandardError => error
      payload = { session_token: session_token, log_data: user.id }
      Gitlab::ExceptionLogFormatter.format!(error, payload)
      Gitlab::ErrorTracking.track_exception(error)
      logger.error(build_message("Error verifying user on Arkose: #{payload}"))

      true
    end

    private

    def add_or_update_arkose_attributes(response)
      return if Gitlab::Database.read_only?

      custom_attributes = custom_attributes(response)

      UserCustomAttribute.upsert_custom_attributes(custom_attributes)
    end

    def custom_attributes(response)
      custom_attributes = []
      custom_attributes.push({ key: 'arkose_session', value: session_id(response) })
      custom_attributes.push({ key: 'arkose_risk_band', value: risk_band(response) })
      custom_attributes.push({ key: 'arkose_global_score', value: global_score(response) })
      custom_attributes.push({ key: 'arkose_custom_score', value: custom_score(response) })

      custom_attributes.map! { |custom_attribute| custom_attribute.merge({ user_id: user.id }) }
      custom_attributes
    end

    def custom_score(response)
      response&.dig('session_risk', 'custom', 'score') || 0
    end

    def global_score(response)
      response&.dig('session_risk', 'global', 'score') || 0
    end

    def risk_band(response)
      response&.dig('session_risk', 'risk_band') || 'Unavailable'
    end

    def session_id(response)
      response&.dig('session_details', 'session') || 'Unavailable'
    end

    def body
      {
        private_key: Settings.arkose['private_key'],
        session_token: session_token,
        log_data: user.id
      }
    end

    def logger
      Gitlab::AppLogger
    end

    def build_message(message)
      Gitlab::ApplicationContext.current.merge(message: message)
    end

    def invalid_token(response)
      response&.key?('error')
    end

    def challenge_solved?(response)
      solved = response&.dig('session_details', 'solved')
      solved.nil? ? true : solved
    end

    def low_risk?(response)
      risk_band = response&.dig('session_risk', 'risk_band')
      risk_band.present? ? risk_band != 'High' : true
    end

    def allowlisted?(response)
      telltale_list = response&.dig('session_details', 'telltale_list') || []
      telltale_list.include?(ALLOWLIST_TELLTALE)
    end
  end
end
