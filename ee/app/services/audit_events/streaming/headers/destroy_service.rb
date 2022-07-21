# frozen_string_literal: true
module AuditEvents
  module Streaming
    module Headers
      class DestroyService < Base
        def execute
          super

          header = params[:header]
          return header_error if header.blank?

          if header.destroy
            audit(action: :destroy, header: header, message: audit_message(header.key))
            ServiceResponse.success
          else
            ServiceResponse.error(message: Array(header.errors))
          end
        end

        private

        def header_error
          ServiceResponse.error(message: "missing header param")
        end

        def audit_message(key)
          "Destroyed a custom HTTP header with key #{key}."
        end
      end
    end
  end
end
