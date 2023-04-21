# frozen_string_literal: true

module Arkose
  class VerifyResponse
    attr_reader :response

    InvalidResponseFormatError = Class.new(StandardError)

    ALLOWLIST_TELLTALE = 'gitlab1-whitelist-qa-team'
    RISK_BAND_HIGH = 'High'
    RISK_BAND_MEDIUM = 'Medium'
    RISK_BAND_LOW = 'Low'
    ARKOSE_RISK_BANDS = [RISK_BAND_LOW, RISK_BAND_MEDIUM, RISK_BAND_HIGH].freeze

    def initialize(response)
      unless response.is_a? Hash
        raise InvalidResponseFormatError, "Arkose Labs Verify API returned a #{response.class} instead of of an object"
      end

      @response = response
    end

    def invalid_token?
      response&.key?('error')
    end

    def error
      response["error"]
    end

    def challenge_solved?
      solved = response&.dig('session_details', 'solved')
      solved.nil? ? true : solved
    end

    def low_risk?
      return true unless Feature.enabled?(:arkose_labs_prevent_login)

      risk_band.present? ? risk_band != 'High' : true
    end

    def allowlisted?
      telltale_list = response&.dig('session_details', 'telltale_list') || []
      telltale_list.include?(ALLOWLIST_TELLTALE)
    end

    def custom_score
      response&.dig('session_risk', 'custom', 'score') || 0
    end

    def global_score
      response&.dig('session_risk', 'global', 'score') || 0
    end

    def risk_band
      response&.dig('session_risk', 'risk_band') || 'Unavailable'
    end

    def session_id
      response&.dig('session_details', 'session') || 'Unavailable'
    end

    def risk_category
      response&.dig('session_risk', 'risk_category') || 'Unavailable'
    end

    def global_telltale_list
      response&.dig('session_risk', 'global', 'telltales') || 'Unavailable'
    end

    def custom_telltale_list
      response&.dig('session_risk', 'custom', 'telltales') || 'Unavailable'
    end
  end
end
