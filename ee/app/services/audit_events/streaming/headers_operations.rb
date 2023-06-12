# frozen_string_literal: true

module AuditEvents
  module Streaming
    module HeadersOperations
      def create_header(destination, key, value)
        header = destination.headers.new(key: key, value: value)

        return true, ServiceResponse.success(payload: { header: header, errors: [] }), header if header.save

        [false, ServiceResponse.error(message: Array(header.errors)), nil]
      end
    end
  end
end
