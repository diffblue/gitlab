# frozen_string_literal: true

module Arkose
  class StatusService
    # https://developer.arkoselabs.com/docs/arkose-labs-api-status-and-health-checks#real-time-arkose-labs-api-status
    ARKOSE_STATUS_URL = 'https://status.arkoselabs.com/api/v2/status.json'
    ARKOSE_SUCCESS_INDICATOR = %w[none minor].freeze

    def execute
      response = Gitlab::HTTP.perform_request(Net::HTTP::Get, ARKOSE_STATUS_URL, {}).parsed_response

      indicator = response.dig('status', 'indicator')

      if ARKOSE_SUCCESS_INDICATOR.include?(indicator)
        success
      else
        error(indicator)
      end

    rescue Timeout::Error, *Gitlab::HTTP::HTTP_ERRORS
      error
    end

    def success
      ServiceResponse.success
    end

    def error(indicator = 'unknown')
      error_message = "Arkose outage, status: #{indicator}"

      ::Gitlab::AppLogger.error(error_message)
      ServiceResponse.error(message: error_message)
    end
  end
end
