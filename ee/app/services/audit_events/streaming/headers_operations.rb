# frozen_string_literal: true

module AuditEvents
  module Streaming
    module HeadersOperations
      def create_header(destination, key, value)
        header = destination.headers.new(key: key, value: value)

        if header.save
          audit_message = "Created custom HTTP header with key #{key}."
          audit(action: :create, header: header, message: audit_message)

          ServiceResponse.success(payload: { header: header, errors: [] })
        else
          ServiceResponse.error(message: Array(header.errors))
        end
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
