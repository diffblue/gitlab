# frozen_string_literal: true
module AuditEvents
  module Streaming
    module Headers
      class UpdateService < Base
        def execute
          super

          header = params[:header]
          return header_error if header.blank?

          update_header(header, params[:key], params[:value])
        end

        private

        def header_error
          ServiceResponse.error(message: "missing header param")
        end
      end
    end
  end
end
