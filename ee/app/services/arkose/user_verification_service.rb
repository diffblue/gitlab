# frozen_string_literal: true
module Arkose
  class UserVerificationService
    attr_reader :url, :session_token, :user, :response

    ARKOSE_LABS_DEFAULT_NAMESPACE = 'client'
    ARKOSE_LABS_DEFAULT_SUBDOMAIN = 'verify-api'

    def initialize(session_token:, user:)
      @session_token = session_token
      @user = user
    end

    def execute
      json_response = Gitlab::HTTP.perform_request(Net::HTTP::Post, arkose_verify_url, body: body).parsed_response
      @response = VerifyResponse.new(json_response)

      logger.info(build_message)

      return false if response.invalid_token?

      add_or_update_arkose_attributes

      response.allowlisted? || (response.challenge_solved? && response.low_risk?)
    rescue StandardError => error
      payload = { session_token: session_token, log_data: user.id }
      Gitlab::ExceptionLogFormatter.format!(error, payload)
      Gitlab::ErrorTracking.track_exception(error)
      logger.error("Error verifying user on Arkose: #{payload}")

      true
    end

    private

    def add_or_update_arkose_attributes
      return if Gitlab::Database.read_only?

      UserCustomAttribute.upsert_custom_attributes(custom_attributes)
    end

    def custom_attributes
      custom_attributes = []
      custom_attributes.push({ key: 'arkose_session', value: response.session_id })
      custom_attributes.push({ key: 'arkose_risk_band', value: response.risk_band })
      custom_attributes.push({ key: 'arkose_global_score', value: response.global_score })
      custom_attributes.push({ key: 'arkose_custom_score', value: response.custom_score })

      custom_attributes.map! { |custom_attribute| custom_attribute.merge({ user_id: user.id }) }
      custom_attributes
    end

    def body
      {
        private_key: Settings.arkose_private_api_key,
        session_token: session_token,
        log_data: user.id
      }
    end

    def logger
      Gitlab::AppLogger
    end

    def build_message
      Gitlab::ApplicationContext.current.symbolize_keys.merge(
        {
          message: 'Arkose verify response',
          response: response.response,
          username: user.username
        }.merge(arkose_payload)
      )
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
