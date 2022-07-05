# frozen_string_literal: true

module ExternalStatusChecks
  class DispatchService
    REQUEST_BODY_SIZE_LIMIT = 25.megabytes

    attr_reader :rule, :data

    def initialize(rule, data)
      @rule = rule
      @data = data
    end

    def execute
      response = Gitlab::HTTP.post(rule.external_url, body: Gitlab::Json::LimitedEncoder.encode(data, limit: REQUEST_BODY_SIZE_LIMIT))

      if response.success?
        ServiceResponse.success(payload: { rule: rule }, http_status: response.code)
      else
        ServiceResponse.error(message: 'Service responded with an error', http_status: response.code)
      end
    end
  end
end
