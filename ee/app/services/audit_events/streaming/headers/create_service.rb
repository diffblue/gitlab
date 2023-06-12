# frozen_string_literal: true

module AuditEvents
  module Streaming
    module Headers
      class CreateService < Base
        def execute
          super

          success, response, header = create_header(destination, params[:key], params[:value])

          audit(action: :create, header: header, message: audit_message(header.key)) if success

          response
        end

        private

        def audit_message(key)
          "Created custom HTTP header with key #{key}."
        end
      end
    end
  end
end
