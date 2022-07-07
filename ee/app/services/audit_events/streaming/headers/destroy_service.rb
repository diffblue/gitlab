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
            ServiceResponse.success
          else
            ServiceResponse.error(message: Array(header.errors))
          end
        end

        private

        def header_error
          ServiceResponse.error(message: "missing header param")
        end
      end
    end
  end
end
