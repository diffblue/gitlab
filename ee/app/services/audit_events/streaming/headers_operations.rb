# frozen_string_literal: true

module AuditEvents
  module Streaming
    module HeadersOperations
      def create_header(destination, key, value)
        header = destination.headers.new(key: key, value: value)

        return true, ServiceResponse.success(payload: { header: header, errors: [] }), header if header.save

        [false, ServiceResponse.error(message: Array(header.errors)), nil]
      end

      def update_header(header, key, value)
        if header.update(key: key, value: value)
          [true, ServiceResponse.success(payload: { header: header, errors: [] })]
        else
          [false, ServiceResponse.error(message: Array(header.errors))]
        end
      end

      def destroy_header(header)
        return true, ServiceResponse.success if header.destroy

        [false, ServiceResponse.error(message: Array(header.errors))]
      end
    end
  end
end
