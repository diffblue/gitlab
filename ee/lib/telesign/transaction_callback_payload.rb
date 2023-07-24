# frozen_string_literal: true

#
# https://developer.telesign.com/enterprise/docs/transaction-callback-service#schema
#
module Telesign
  class TransactionCallbackPayload
    attr_reader :payload

    def initialize(json)
      @payload = json
    end

    def reference_id
      payload['reference_id']
    end

    def status
      code = payload.dig('status', 'code')
      description = payload.dig('status', 'description')
      [code, description].compact.join(' - ')
    end

    def status_updated_on
      payload.dig('status', 'updated_on')
    end

    def errors
      return '' unless payload['errors'].is_a?(Array)

      payload['errors'].map do |error|
        [error['code'], error['description']].compact.join(' - ')
      end.join(', ')
    end
  end
end
