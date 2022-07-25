# frozen_string_literal: true
module AuditEvents
  module Streaming
    module Headers
      class CreateService < Base
        def execute
          super

          header = destination.headers.new(key: params[:key], value: params[:value])

          if header.save
            audit(action: :create, header: header, message: audit_message(header.key))
            ServiceResponse.success(payload: { header: header, errors: [] })
          else
            ServiceResponse.error(message: Array(header.errors))
          end
        end

        private

        def audit_message(key)
          "Created custom HTTP header with key #{key}."
        end
      end
    end
  end
end
